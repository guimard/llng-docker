  </div>

  <div class="col-3 d-none d-xl-block" id="floating-menu"></div>

  <div id="footer" class="container-fluid mt-5">
    <div class="row p-1">
      <div class="col"></div>
      <div class="col-md-8">
      <TMPL_INCLUDE NAME="customfooter.tpl">
      </div>
      <div class="col text-end">
      <TMPL_IF NAME="LANGS">
        <span id="languages"></span>
      </TMPL_IF>
      </div>
    </div>
  </div>

<!-- Constants -->
<script type="text/JavaScript" src="<TMPL_VAR NAME="SCRIPTNAME">psgi.js"></script>
</body>
</html>

