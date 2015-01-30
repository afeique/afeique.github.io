#!/usr/bin/python

from buildbot.status.web.baseweb import WebStatus
from sqlalchemy import create_engine
from root import BuildtrackerRoot

class BuildtrackerWebStatus(WebStatus):
    buildtrackerDbCon   = None
    buildbotDbCon       = None
    builders            = []

    @staticmethod
    def setup(buildtracker_dburl, buildbot_dburl, buildmaster_path):
        # create engines and connect to databases
        BuildtrackerWebStatus.buildtrackerDbCon = create_engine(buildtracker_dburl).connect()
        BuildtrackerWebStatus.buildbotDbCon = create_engine(buildbot_dburl).connect()
        BuildtrackerWebStatus.buildmaster_path = buildmaster_path

    def setupUsualPages(self, numbuilds, num_events, num_events_max):
        # run parent logic to setup the usual pages
        WebStatus.setupUsualPages(self, numbuilds, num_events, num_events_max)

        # setup our context pages
        self.putChild('buildtracker', BuildtrackerRoot(
            buildtrackerDbCon=BuildtrackerWebStatus.buildtrackerDbCon,
            buildbotDbCon=BuildtrackerWebStatus.buildbotDbCon,
            buildmaster_path=BuildtrackerWebStatus.buildmaster_path
        ))
        
# shhhh
_hush_pyflakes = [BuildtrackerWebStatus]
