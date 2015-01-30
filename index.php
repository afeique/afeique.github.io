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
			I am a programmer and engineer who revels in learning and technical problem-solving.
		</p>
        <p>
		<a class="btn btn-success btn-lg" style="font-size:.8em;" href="files/Resume.pdf" role="button" target="_blank">
		Résumé
		<br><em><small><?=date('F j, Y', filemtime('files/Resume.pdf'))?></small></em>
		</a>
		</p>
      </div>

      <div class="row marketing">
        <div class="col-lg-6">
          <h4 id="past">Buildtracker</h4>
          <h5>2014</h5>
          <p>
            An extension for the open-source <a href="http://buildbot.net/" target="_blank">Buildbot</a> software. Written mostly in Python with supporting scripts in Bash and Perl. (<a href="files/buildtracker.png" target="_blank">screenshot</a>)
          </p>
          <p>
            Like Buildbot, the extension uses <a href="http://www.sqlalchemy.org/">SQLAlchemy</a> for database <a href="http://en.wikipedia.org/wiki/Object-relational_mapping" target="_blank">ORM</a> and <a href="http://jinja.pocoo.org/">Jinja2</a> for templating.
          </p>
        </div>

        <div class="col-lg-6">
          
        <h4>Condenser Microphone</h4>
          <h5>2014</h5>
		 		<p>
		    	Attempted to design a condenser microphone for a capstone in <em>Sensor System Design</em>, Spring 2014. The <a href="files/capstone/report.pdf">final report</a> closely follows IEEE format and is available <a href="https://github.com/afeique/18510-report" target="_blank">in LaTeX</a>.
		  	</p>
			</div>  
		</div>

        <div class="col-lg-6">
		  <h4>FPGA Pong</h4>
          <h5>2013</h5>
		  <p>Implementation of color <a href="http://en.wikipedia.org/wiki/Pong" target="_blank">Pong</a> for an FPGA using SystemVerilog. Ran on a <a href="http://www.xilinx.com/products/silicon-devices/fpga/spartan-3.html" target="_blank">Xilinx Spartan-3</a>.</p>
		  <ul>
		    <li><a href="files/fpga/vga.sv" target="_blank">vga.sv</a> - Timing-based module for outputting to monitor using VGA.</li>
			<li><a href="files/fpga/lib.sv" target="_blank">lib.sv</a> - Library of Pong-specific modules.</li>
		  </ul>
		</div>
        
        <div class="col-lg-6">
          <h4>Former Personal Website</h4>
          <h5>2012</h5>
          <p>
			A fun foray into the development of an article-based system using my own experimental <a href="http://en.wikipedia.org/wiki/Model-view-controller" target="_blank">MVC</a> framework written in PHP.
          </p>
          <p>
            The <a href="http://github.com/afeique/afeique.com-old">website source</a> is freely available under the public domain.
          </p>
        </div>

		  
        <div class="col-lg-6">
		  <h4>Matlab Functions</h4>
          <h5>2013</h5>
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

	    <div class="col-lg-6">
	      <h4>Acrosstime</h4>
          <h5>2012 - Present</h5>
	      <p>
	        Independent project that's been mostly inactive over the past few years, but not abandoned. Continuation of <a href="https://web.archive.org/web/20090618070700/http://robosquid.com/" target="_blank">RoboSquid</a>. An attempt at a community-based CMS focused on spurring artistic productivity and creativity. A <a href="https://github.com/afeique/at" target="_blank">code snapshot</a> is available.
	      </p>	
	    </div>
	  
	  </div>
	  
	  <hr>

	  <div class="footer">
	    <p>
	      "Nowadays most people die of a sort of creeping common sense, and discover when it is too late that the only things one never regrets are one's mistakes."&mdash;from <em>The Picture of Dorian Gray</em> by Oscar Wilde
		</p>
		<p>
		  <em>&copy; <?=date('Y')?></em>
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
