<!DOCTYPE html>

<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="(づ｡◕‿‿◕｡)づ">
<meta name="author" content="afeique sheikh">

<!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="css/bootstrap.min.css">

<!-- SOURCE: http://getbootstrap.com/examples/jumbotron-narrow/ -->
<link href="css/jumbotron-narrow.css" rel="stylesheet">
<link href="css/custom.css" rel="stylesheet">


<title>afeique sheikh's digital portfolio (ﾉ◕ヮ◕)ﾉ</title>
<!--
<title>/ah'fēk shēk/</title>
-->
</head>

<body>
  <div class="container">
      <div class="header">
        <ul class="nav nav-pills pull-right">
          <li><a href="#past">past work</a></li>
          <!-- <li><a href="wp">blog</a></li> -->
        </ul>
        <h3>afeique sheikh&nbsp;<small><em>ah'fēk shēk</em></small></h3>
      </div>

      <div class="jumbotron">
        <p class="lead">
			I am a programmer, engineer, mathematologer, ponderer, wonderer, wanderer, philosopher, writer, 
			photographer, videographer, guitarist, singer, manual driver,
			hex-loving, physics-attuned, html-dreaming, bit-banging, base-2 junkie.
			<br />
			<br />
			I am a
			<a href="https://en.wikipedia.org/wiki/Cascading_Style_Sheets" target="_blank">css</a> slurper,
			<a href="https://en.wikipedia.org/wiki/The_C_Programming_Language" target="_blank">c</a>-believer,
			<a href="https://en.wikipedia.org/wiki/Object-oriented_programming" target="_blank">object-oriented</a>,
			memory manipulating,
			<a href="https://en.wikipedia.org/wiki/The_C_Programming_Language">Kernighan and Ritchie</a> fanatic,
			<a href="https://jquery.com/" target="_blank">jquery</a> consumerist,
			<a href="http://www.vim.org/" target="_blank">vim</a> enthusiast, 
			<a href="https://www.sublimetext.com/">sublime</a> lover, 
			<a href="https://git-scm.com/" target="_blank">git</a> backer-upper, 
			<a href="http://python.org/" target="_blank">python</a> slytherin,
			<a href="https://secure.php.net/" target="_blank">php</a> MVC mason,
			<a href="https://www.perl.org/" target="_blank">perl</a> jammer,
			<a href="https://dev.mysql.com/" target="_blank">mysqlist</a>,
			<a href="https://www.postgresql.org/" target="_blank">pro-postgresqler</a>
			and genuine <u>everyman</u>.
			<br />
			<br />
			My plethora of abilities are finely honed towards: <br />
		</p>
		<ul>
			<li>precise technical communication in the english language,</li>
			<li>quality aesthetics and clean, maintainable code,</li>
			<li>analytical problem-solving,</li>
			<li>full-stack development,</li>
			<li>audio-visual editing,</li>
			<li>photo capturing,</li> 
			<li>music making,</li> 
			<li>linux tinkering, 
			<li>programming,</li>
			<li>logic-ocd.</li>
		</ul>
		<p class="lead">
			and the countless combinations therewithin. 
			<br />
			<br />
			To learn how I can be of service to you or your organization, don't hesitate to contact me.
        </p>
        <br />
        <p>
          <a class="btn btn-success btn-lg" style="font-size:.8em;" href="files/Resume.pdf" role="button" target="_blank">
            Résumé
            <br><em><small><?=date('F j, Y', filemtime('files/Resume.pdf'))?></small></em>
          </a>
          <a class="btn btn-success btn-lg" style="font-size:.8em;" href="http://github.com/afeique" role="button" target="_blank">
            GitHub
            <br><em><small>&lt;code&gt;</small></em>
          </a>
        </p>
      </div>

      <div id="past" class="row marketing">
        <h4>2016</h4>

        <h5>HtmlReports (<a href="http://github.com/afeique/HtmlReports" target="_blank">project</a>)</h5>
        <div class="col-lg-12">
          <p>
            A set of Python 2.7 scripts designed to take JSON input and produce clean, navigable HTML reports. The HTML templates are written using <a href="http://jinja.pocoo.org/">Jinja2</a>. Originally, <a href="http://www.makotemplates.org/" target="_blank">Mako</a> was going to be used as the templating engine.
          </p>
        </div>
      </div>
      
      <div class="row marketing">
        <h4>2015</h4>

        <h5>ZenPortal Requests (<a href="http://github.com/afeique/zpr-sample" target="_blank">sample code</a>)</h5>
        <div class="col-lg-12">
          <p>
            Complete requests management system written using the <a href="http://fuelphp.com/" target="_blank">FuelPHP framework</a>.
          </p>
          
        </div>

        <h5>Bootman</h5>
        <div class="col-lg-12">
          <p>
            Command-line perl script designed to manage kernel images for boot-testing boards connected to board-farm server. Complemented by a web-interface written using <a href="http://webpy.org/" target="_blank">web.py</a>.
          </p>
          <ul>
            <li><a href="files/bootman/main.pl">main.pl</a> - perl script used to manage boards.</li>
            <li><a href="files/bootman/setup.sh">setup.sh</a> - bash script used to setup kernel images.</li>
            <li><a href="files/bootman/verify.pl">verify.pl</a> - perl script used to aid in taking physical inventory and committing a list of valid boards to the database.</li>
            <li><a href="files/bootman/web.zip">web.zip</a> - web.py interface.</li>
        </div>
      </div>

      <div class="row marketing">
        <h4>2014</h4>

        <h5>Buildtracker</h5>
        <div class="col-lg-12">
          <p>
            An extension for the open-source <a href="http://buildbot.net/" target="_blank">Buildbot</a> software. Written mostly in Python 2.7 with supporting scripts in Bash and Perl. (<a href="files/buildtracker.png" target="_blank">screenshot</a>)
          </p>
          <p>
            Like Buildbot, the extension uses <a href="http://www.sqlalchemy.org/">SQLAlchemy</a> for database <a href="http://en.wikipedia.org/wiki/Object-relational_mapping" target="_blank">ORM</a> and <a href="http://jinja.pocoo.org/">Jinja2</a> for templating.
          </p>
          <ul>
            <li><a href="files/buildtracker/root.py" target="_blank">root.py</a> - Primary python controller.</li>
            <!--
            <li><a href="files/buildtracker/webstatus.py" target="_blank">webstatus.py</a> - Interface class that encapsulates the BuildtrackerRoot class above and extends the Buildbot web interface.</li>
            -->
            <li><a href="files/buildtracker/buildtracker_macros.html.src" target="_blank">buildtracker_macros.html</a> - Jinja2 template macros.</li>
            <!--
            <li><a href="files/buildtracker/buildtracker_root.html.src" target="_blank">buildtracker_root.html</a> - Actual template using above macros.</li>
            <li><a href="files/buildtracker/add_entropy.sh" target="_blank">add_entropy.sh</a> - Bash script to add entropy to workorder configuration.</li>
            -->
            <li><a href="files/buildtracker/add_rdeps.pl" target="_blank">add_rdeps.pl</a> - Perl script to select a random number of reverse dependencies.</li>
            <li><a href="files/buildtracker/file-build-failure.pl" target="_blank">file-build-failure.pl</a> - Perl script to post a bug via XML-RPC.</li>
          </ul>
        </div>

        <h5>Condenser Microphone</h5>
        <div class="col-lg-12">
          <p>
            Attempted to design a condenser microphone for a capstone in <em>Sensor System Design</em>, Spring 2014. The <a href="files/capstone/report.pdf">final report</a> closely follows IEEE format and is available <a href="https://github.com/afeique/18510-report" target="_blank">in LaTeX</a>.
          </p>      
        </div>

        <h5>Matlab Functions</h5>
        <div class="col-lg-12">
          <p>Trivial Matlab functions used in coursework:</p>
          <ul>
            <li><a href="files/matlab/Crout.m">Crout.m</a> - matrix decomposition</li>
            <li><a href="files/matlab/BackSub.m">BackSub.m</a> - matrix back-substitution</li>
            <li><a href="files/matlab/ForwardSub.m">ForwardSub.m</a> - matrix forward-substitution</li>
            <li><a href="files/matlab/Inverse.m">Inverse.m</a> - matrix inverse</li>
            <li><a href="files/matlab/Solve.m">Solve.m</a> - solves matrix equations</li>
            <li><a href="files/matlab/LinReg.m">LinReg.m</a> - linear regression coefficients</li>
            <li><a href="files/matlab/PolyFit.m">PolyFit.m</a> - n<sup>th</sup> order polynomial fitting</li>
          </ul>
        </div>
      </div>

      <div class="row marketing">
        <h4>2013</h4>

        <h5>FPGA Pong</h5>
        <div class="col-lg-12">
          <p>Implementation of color <a href="http://en.wikipedia.org/wiki/Pong" target="_blank">Pong</a> for an FPGA using SystemVerilog. Ran on a <a href="http://www.xilinx.com/products/silicon-devices/fpga/spartan-3.html" target="_blank">Xilinx Spartan-3</a>.</p>
          <ul>
           <li><a href="files/fpga/vga.sv" target="_blank">vga.sv</a> - Timing-based module for outputting to monitor using VGA.</li>
           <li><a href="files/fpga/lib.sv" target="_blank">lib.sv</a> - Library of Pong-specific modules.</li>
          </ul>
        </div>
      </div>
        
      <div class="row marketing">
        <h4>2012</h4>

        <h5>Former Personal Website</h5>
        <div class="col-lg-12">
          <p>
            A fun foray into the development of an article-based system using my own experimental <a href="http://en.wikipedia.org/wiki/Model-view-controller" target="_blank">MVC</a> framework written in PHP.
          </p>
          <p>
            The defining feature of my framework was a simple set of classes dubbed "OOHTML" that utilized a pardigm of encapsulating and rendering HTML entirely using objects.
          </p>
          <p>
            Both the <a href="http://github.com/afeique/oohtml" target="_blank">OOHTML classes</a> and <a href="http://github.com/afeique/afeique.com-old">website source</a> are freely available under the public domain.
          </p>
        </div>
      </div>


      <div class="row marketing">
        <h4>2012 - Present</h4>

        <h5>Acrosstime</h5>
        <div class="col-lg-12">
          <p>
            Independent project that's been mostly inactive over the past few years, but not abandoned. Continuation of <a href="https://web.archive.org/web/20090618070700/http://robosquid.com/" target="_blank">RoboSquid</a>. An attempt at a community-based CMS focused on spurring artistic productivity and creativity.           
          </p>  
        </div>
      </div>
    
      <hr>

      <div class="footer">
        <p>
          "Nowadays most people die of a sort of creeping common sense, and discover when it is too late that the only things one never regrets are one's mistakes."&mdash;from <em>The Picture of Dorian Gray</em> by Oscar Wilde
        </p>
        <p>
          <em>2014 &ndash; <?=date('Y')?></em><br />
          <a href="https://github.com/afeique/afeique.com" target="_blank">source code</a>
        </p>
      </div>
      
    </div><!-- /container -->


    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <script src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

      ga('create', 'UA-4925272-3', 'auto');
      ga('require', 'displayfeatures');
      ga('require', 'linkid', 'linkid.js');
      ga('send', 'pageview');
    </script>
</body>
</html>
