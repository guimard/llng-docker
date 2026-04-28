
    <TMPL_IF NAME="CHECK_LOGINS">
    <div class="input-group mb-3">
      <div class="input-group-text flex-grow-1">
        <input type="checkbox" id="checkLogins<TMPL_VAR NAME="key">" name="checkLogins" aria-describedby="checkLoginsLabel" <TMPL_IF NAME="ASK_LOGINS">checked</TMPL_IF> />
        <label id="checkLoginsLabel" for="checkLogins<TMPL_VAR NAME="key">" class="ms-2 mb-0" trspan="checkLastLogins">Check my last logins</label>
      </div>
    </div>
    </TMPL_IF>
    <TMPL_IF NAME="STAYCONNECTED">
      <TMPL_IF NAME="BROWSER_ALREADY_TRUSTED">
      <div class="message message-success alert alert-success"><span trspan="browserAlreadyTrusted">This browser is already trusted</span></div>
      <TMPL_ELSE>
    <div class="input-group mb-3">
      <div class="input-group-text flex-grow-1">
        <input type="checkbox" id="stayconnected" name="stayconnected" aria-describedby="stayConnectedLabel" <TMPL_IF NAME="ASK_STAYCONNECTED">checked</TMPL_IF> />
        <label id="stayConnectedLabel" for="stayconnected" class="ms-2 mb-0" trspan="stayConnected">Stay connected on this device</label>
      </div>
    </div>
      </TMPL_IF>
    </TMPL_IF>
