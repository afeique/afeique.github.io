#!/usr/bin/python

from buildbot.status.web.base import HtmlResource, BuildLineMixin, path_to_root
# from logs import *
from models import *
from sqlalchemy import *
from glob import glob
import re
import bz2
from subprocess import call
from datetime import datetime
from time import time
from twisted.python import log

class BuildtrackerRoot(HtmlResource, BuildLineMixin):
    pageTitle = "Buildtracker"

    def __init__(self, buildtrackerDbCon, buildbotDbCon, buildmaster_path):
        HtmlResource.__init__(self)
        self.buildtrackerDbCon = buildtrackerDbCon
        self.buildbotDbCon = buildbotDbCon
        self.buildmaster_path = buildmaster_path

    def getChild(self, path, req):
        if path is "logs":
            return BuildtrackerLogsResource(self.buildtrackerDbCon)

        return HtmlResource.getChild(self, path, req)


    def content(self, req, cxt):
        keyword = str(req.args.get("keyword", [''])[0])
        keyword_field = str(req.args.get("keyword_field", [0])[0])
        status_filter = int(req.args.get("status_filter", [-1])[0])
        result_filter = int(req.args.get("result_filter", [-1])[0])
        sort_order = int(req.args.get("sort_order", [-1])[0])
        limit = int(req.args.get("limit", [200])[0])
        offset = int(req.args.get("offset", [0])[0])
        cxt["form"] = {
            "keyword": keyword,
            "keyword_field": keyword_field,
            "status_filter": status_filter,
            "result_filter": result_filter,
            "sort_order": sort_order,
            "limit": limit,
            "offset": offset
        }
        cxt["selected_builds"] = selected_builds = [int(build_number) for build_number in req.args.get("selected_builds[]", [])]
        log.msg("BuildtrackerRoot: selected builds "+ str(selected_builds))
        cxt["notifications"] = []

        # buildtracker model aliases
        BuildtrackerBuilds_t = BuildtrackerModels.Build


        # perform requested action (acknowledge, reset, delete) on selected builds
        action = req.args.get("action", [None])[0]
        if action is not None:
            action = str(action)

        #
        # STEP 1: Perform basic actions.
        #
        # A "basic" action is an action that does not require us to have a dict of the actual
        # build.
        #

        basic_actions = ["acknowledge", "reset", "delete"]
        advanced_actions = ["file-bugs"]
        if selected_builds and action in basic_actions:
            where_block = BuildtrackerBuilds_t.c.number.in_(selected_builds)
            num_selected = len(selected_builds)
            s = '' if num_selected == 1 else 's'
            num_selected = str(num_selected)
            if action == "acknowledge":
                q = BuildtrackerBuilds_t.update().where(where_block).values(acked=True)
                log_msg = "Acknowledged " + num_selected + " build"+s
                self.log_and_notify(cxt, log_msg)
            elif action == "reset":
                q = BuildtrackerBuilds_t.update().where(where_block).values(acked=False)
                log_msg = "Reset " + num_selected + " acknowledgement"+s
                self.log_and_notify(cxt, log_msg)
            elif action == "delete":
                q = BuildtrackerBuilds_t.delete().where(where_block)
                log_msg = "Deleted " + num_selected + " build"+s
                self.log_and_notify(cxt, log_msg)

            # execute query on selected builds
            self.buildtrackerDbCon.execute(q)

                # TEMPORARY: delete logs copied to public_html, need to look these up in the build table first
#                log_path = self.buildmaster_path + "public_html/logs/"
#                tail_log = log_path + build["tail_log"]
#                full_log = log_path + build["full_log"]
#                subprocess.call(["rm", tail_log])
#                subprocess.call(["rm", full_log])

        #
        # STEP 2: Generate query for filtered builds
        #


        # filter based on acknowledgement status (acked or unacked)
        where_ack = (BuildtrackerBuilds_t.c.acked == False) | (BuildtrackerBuilds_t.c.acked == True)
        if status_filter is -1:
            where_ack = (BuildtrackerBuilds_t.c.acked == False)
        elif status_filter is 1:
            where_ack = (BuildtrackerBuilds_t.c.acked == True)

        # filter based on keyword
        where_keyword_field = None
        if keyword_field == "slavename":
            where_keyword_field = BuildtrackerBuilds_t.c.slavename
        elif keyword_field == "board":
            where_keyword_field = BuildtrackerBuilds_t.c.board
        elif keyword_field == "package":
            where_keyword_field = BuildtrackerBuilds_t.c.package
        elif keyword_field == "branch":
            where_keyword_field = BuildtrackerBuilds_t.c.branch

        # filter based on build result (failure or success)
        where_result = (BuildtrackerBuilds_t.c.status >= 0)
        if result_filter is -1:
            where_result = (BuildtrackerBuilds_t.c.status > 0)
        elif result_filter is 1:
            where_result = (BuildtrackerBuilds_t.c.status == 0)

        # determine sort order
        order = BuildtrackerBuilds_t.c.finish_time.desc()
        if sort_order is 1:
            order = BuildtrackerBuilds_t.c.finish_time.asc()

        # fetch filtered list of buildtracker builds to display

        where_query = where_ack & where_result
        if keyword and where_keyword_field is not None:
            where_query = where_query & where_keyword_field.like("%"+ keyword +"%")

        filtered_builds_q = select([
            BuildtrackerBuilds_t
        ]).select_from(
            BuildtrackerBuilds_t
        ).where(where_query).order_by(order).limit(limit).offset(offset)


        #
        # STEP 3: Get filtered builds
        #

        # log.msg("BuildtrackerRoot: keyword='%s'" % keyword)
        # log.msg("BuildtrackerRoot: keyword_field='%s'" % keyword_field)
        # log.msg("BuildtrackerRoot: %s" % q)

        # get filtered builds
        r = self.buildtrackerDbCon.execute(filtered_builds_q).fetchall()
        filtered_builds = [dict(row.items()) for row in r]


        # 
        # STEP 4: Perform advanced actions
        #
        # An "advanced" action is one that requires us to have a dict of the build.
        # Performing an advanced action will require us to re-query the database for an
        # updated list of filtered builds.
        #

        bug_filing_time = float('0')
        bugs_filed_for = []
        # file bugs for selected builds
        for build in filtered_builds:
            #log.msg("BuildtrackerRoot: for build "+ str(build["number"]) +", bug_filed="+ str(build["bug_filed"]))

            if action == "file-bugs" and build["number"] in selected_builds and build["bug_filed"] == False:
                log_path = self.buildmaster_path + "public_html/logs/" + build["builder"] + "/"
                args = []
                #args.append("--uri=http://mirror/bugzilla/xmlrpc.cgi")
                #args.append("--login=afeique.sheikh@timesys.com")
                #args.append("--password=time123")
                args.append("--builder=" + build["builder"])
                if build["package"]:
                    args.append("--package=" + build["package"])

                if not build["revision"]:
                    build["revision"] = "HEAD"

                args.append("--commit=" + build["revision"])
                args.append("--buildnum=" + str(build["number"]))
                if build["board"]:
                    args.append("--board=" + build["board"])
                else:
                    args.append("--board=dummy_board")
                #args.append("--logfull=" + log_path + build["full_log"])
                args.append("--logtail=" + log_path + build["tail_log"])
                args.append("--workorder=" + log_path + build["workorder_log"])
                args.append("--os=" + build["slavename"])
                args = ' '.join(args)

                # generate command with args to file the bug using perl script
                file_bug_cmd = self.buildmaster_path + "scripts/file-build-failure.pl " + args

                # output the command we use to the notifications for debug/testing
                # cxt["notifications"].append(file_bug_cmd)
                log.msg("BuildtrackerRoot: %s" % file_bug_cmd)

                # measure the time it takes to file the bug
                start_time = time()

                # call the perl script
                call(file_bug_cmd, shell=True)

                # log the time it took the script
                script_time = time() - start_time
                log_msg = "Took %.2f seconds to file bug for build #%d" % (script_time, build["number"])
                #cxt["notifications"].append(log_msg)
                log.msg("BuildtrackerRoot: %s" % log_msg)

                bugs_filed_for.append(build["number"])
                bug_filing_time += script_time
                build["bug_filed"] = True

        # if we filed bugs for selected builds, update the database and produce a notification
        if bugs_filed_for:
            where_block = BuildtrackerBuilds_t.c.number.in_(bugs_filed_for)
            num_bugs_filed = len(bugs_filed_for)
            q = BuildtrackerBuilds_t.update().where(where_block).values(acked=True, bug_filed=True)
            self.buildtrackerDbCon.execute(q)

            s = '' if num_bugs_filed == 1 else 's'
            num_bugs_files = str(num_bugs_filed)

            log_msg = "Acknowledged and filed bug"+s+" for " + str(num_bugs_filed) + " build"+s+(" (%.2f seconds)" % bug_filing_time)
            self.log_and_notify(cxt, log_msg)

        #
        # STEP 4: If an advanced action was performed, re-query for updated list of filtered builds
        #

        if action in advanced_actions:
            # re-filter builds
            r = self.buildtrackerDbCon.execute(filtered_builds_q).fetchall()
            filtered_builds = [dict(row.items()) for row in r]

        #
        # STEP 5: Format final list of filtered builds
        #

        for build in filtered_builds:
            # format timestamps
            # build["started_at"] = datetime.fromtimestamp(build["start_time"]).strftime("%b %d %H:%M")
            build["finished_at"] = datetime.fromtimestamp(build["finish_time"]).strftime("%b %d %H:%M")

            # truncate the revision hash to the first few digits
            if build["revision"]:
                build["short_revision"] = build["revision"][0:7]

            # set urls, hardcode to package_testing for now. maybe we should throw that in db..
            build["builder_url"] = "builders/" + build["builder"]
            build["build_url"] = build["builder_url"] + "/builds/" + str(build["number"])

            build["slave_url"] = "buildslaves/" + build["slavename"]
            # get build changed software (what software changes triggered the build)
            build["changed_software"] = []

        cxt["builds"] = filtered_builds

        # clear selected builds
        selected_builds = []

        template = req.site.buildbot_service.templates.get_template("buildtracker_root.html")
        return template.render(**cxt)

    def log_and_notify(self, cxt, log_msg):
        log.msg("BuildtrackerRoot: " + log_msg)
        cxt["notifications"].append(log_msg)
