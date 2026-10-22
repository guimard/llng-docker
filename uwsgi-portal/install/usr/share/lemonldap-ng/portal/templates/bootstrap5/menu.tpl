<TMPL_INCLUDE NAME="header.tpl">

<main id="menucontent" class="container">

  <TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
  </TMPL_IF>

  <div id="menu">

  <nav class="navbar navbar-expand-lg navbar-light bg-light mb-3">
    <div class="container-fluid">
    <a class="navbar-brand" href="<TMPL_VAR NAME="PORTAL_BASE">"><span trspan="home" hidden></span><i class="fa fa-home"></i></a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>

    <TMPL_IF DISPLAY_MODULES>

    <div class="collapse navbar-collapse" id="navbarSupportedContent">
    <!-- Tabs list -->
      <ul class="navbar-nav me-auto">
        <TMPL_LOOP NAME="DISPLAY_MODULES">

          <TMPL_IF NAME="Appslist">
            <li class="nav-item" id="menu-item-appslist">
              <a class="nav-link" href="#appslist">
                <i class="fa-regular fa-window-restore me-1"></i>
                <span trspan="yourApps">Your applications</span>
              </a>
            </li>
          </TMPL_IF>
          <TMPL_IF NAME="ChangePassword">
            <li class="nav-item" id="menu-item-password">
              <a class="nav-link" href="#password">
                <i class="fa-solid fa-key me-1"></i>
                <span trspan="password">Password</span>
              </a>
            </li>
          </TMPL_IF>
          <TMPL_IF NAME="LoginHistory">
            <li class="nav-item" id="menu-item-loginhistory">
              <a class="nav-link" href="#loginHistory">
                <i class="fa-solid fa-clock-rotate-left me-1"></i>
                <span trspan="loginHistory">Login history</span>
              </a>
            </li>
          </TMPL_IF>
          <TMPL_IF NAME="OidcConsents">
            <li class="nav-item" id="menu-item-oidcconsents">
              <a class="nav-link" href="#oidcConsents">
                <i class="fa-solid fa-list-check me-1"></i>
                <span trspan="oidcConsents">OIDC Consent</span>
              </a>
            </li>
          </TMPL_IF>
          <TMPL_IF NAME="Logout">
            <li class="nav-item" id="menu-item-logout">
              <a class="nav-link" href="#logout">
                <i class="fa-solid fa-right-from-bracket me-1"></i>
                <span trspan="logout">Logout</span>
              </a>
            </li>
          </TMPL_IF>
          <TMPL_IF NAME="_PLUGIN">
            <li class="nav-item" id="menu-item-<TMPL_VAR NAME="_PLUGIN_ID">">
              <a class="nav-link" href="#<TMPL_VAR NAME="_PLUGIN_ID">">
                <i class="fa fa-<TMPL_VAR NAME="_PLUGIN_LOGO"> me-1"></i>
                <span trspan="<TMPL_VAR NAME="_PLUGIN_NAME">"><TMPL_VAR NAME="_PLUGIN_NAME"></span>
              </a>
            </li>
        </TMPL_IF>
        </TMPL_LOOP>
      </ul>

      <ul class="user nav navbar-nav navbar-right">
        <li class="nav-item dropdown">
          <TMPL_IF NAME="DropdownMenu">
          <a href="#" class="nav-link dropdown-toggle" data-bs-toggle="dropdown">
            <span trspan="connectedAs">Connected as</span> <TMPL_VAR NAME="AUTH_USER">
            <span class="caret"></span>
          </a>
          <TMPL_ELSE>
          <div class="text-muted">
            <span trspan="connectedAs">Connected as</span> <TMPL_VAR NAME="AUTH_USER">
          </div>
          </TMPL_IF>
          <TMPL_IF NAME="DropdownMenu">
          <ul class="dropdown-menu" role="menu">
            <TMPL_IF NAME="sfaManager">
              <li class="dropdown-item" role="menuitem" id="menu-item-sfamanager">
                <a href="<TMPL_VAR NAME="PORTAL_BASE">2fregisters" class="nav-link">
                  <i class="fa-solid fa-shield-halved me-1"></i>
                  <span trspan="sfaManager">sfaManager</span>
                </a>
              </li>
            </TMPL_IF>
            <TMPL_IF NAME="Notifications">
              <li class="dropdown-item" role="menuitem" id="menu-item-notificationsexplorer">
                <a href="<TMPL_VAR NAME="PORTAL_BASE">mynotifications" class="nav-link">
                  <i class="fa-solid fa-bell me-1"></i>
                  <span trspan="notificationsExplorer">notificationsExplorer</span>
                </a>
              </li>
            </TMPL_IF>
            <TMPL_IF NAME="DecryptValue">
              <li class="dropdown-item" role="menuitem" id="menu-item-decryptvalue">
                <a href="<TMPL_VAR NAME="PORTAL_BASE">decryptvalue" class="nav-link">
                  <i class="fa-solid fa-eye me-1"></i>
                  <span trspan="decryptCipheredValue">decryptCipheredValue</span>
                </a>
              </li>
            </TMPL_IF>
            <TMPL_IF NAME="ContextSwitching">
              <li class="dropdown-item" role="menuitem" id="menu-item-contextswitching">
                <a href="<TMPL_VAR NAME="PORTAL_BASE">switchcontext" class="nav-link">
                  <TMPL_IF NAME="ContextSwitchingON">
                  <i class="fa-solid fa-person-circle-check text-success me-1"></i>
                  <TMPL_ELSE>
                  <i class="fa-solid fa-person-circle-xmark text-danger me-1"></i>
                  </TMPL_IF>
                  <span trspan="contextSwitching_<TMPL_VAR NAME="contextSwitching">">contextSwitching_<TMPL_VAR NAME="ContextSwitching"></span>
                </a>
              </li>
            </TMPL_IF>
            <TMPL_IF NAME="RefreshMyRights">
              <li class="dropdown-item" role="menuitem" id="menu-item-refreshrights">
                <a href="<TMPL_VAR NAME="PORTAL_BASE">refresh" class="nav-link">
                  <i class="fa-solid fa-arrows-rotate me-1"></i>
                  <span trspan="refreshrights">Refresh</span>
                </a>
              </li>
            </TMPL_IF>
          </ul>
          </TMPL_IF>
        </li>
      </ul>

    </div>
    </TMPL_IF>

    </div>
    </nav>

    <!-- Tabs content -->
    <TMPL_LOOP NAME="DISPLAY_MODULES">

      <TMPL_IF NAME="Appslist">
        <div id="appslist">

          <TMPL_IF NAME="NO_APP_ALLOWED">
            <div class="message message-warning alert"><div class="text-center"><span trspan="noAppAllowed">">None application allowed!</span></div></div>
          <TMPL_ELSE>
          <TMPL_LOOP NAME="APPSLIST_LOOP">
          <!-- Template loops -->

            <TMPL_IF NAME="category">
            <!-- Category -->

              <div class="category cat-level-<TMPL_VAR NAME="catlevel"> <TMPL_VAR NAME="catid"> card border-secondary my-3" name="<TMPL_VAR NAME="catname">" id="sort_<TMPL_VAR NAME="__counter__">" >

                <div class="card-header bg-secondary">
                <h4 class="catname card-title"><TMPL_VAR NAME="catname"><span><i class="fa fa-arrows-v float-end" ></i></span></h4>
                </div>

                  <TMPL_IF applications>
                  <div class="card-body">
                    <!-- Applications -->

                    <div class="row">
                    <TMPL_LOOP NAME=applications>

                      <!-- Application -->
                      <div class="col-md-4 py-1">
                      <div class="application <TMPL_VAR NAME="appid"> p-3 h-100">
                        <a href="<TMPL_VAR NAME="appuri">" title="<TMPL_VAR NAME="apptip">" >

                        <div class="row">
                        <!-- Logo (optional) -->
                        <TMPL_IF NAME="applogo">
                          <div class="col-3">
                          <TMPL_IF NAME="applogo_icon">
                          <span class="applogo fa-3x fa fa-<TMPL_VAR NAME="applogo"> <TMPL_VAR NAME="appid">"></span>
                          <TMPL_ELSE>
                          <img src="<TMPL_VAR NAME="STATIC_PREFIX">common/apps/<TMPL_VAR NAME="applogo">"
                            class="applogo <TMPL_VAR NAME="appid"> img-fluid"
                            alt="" />
                          </TMPL_IF>
                          </div>
                          <div class="col-9">
                        <TMPL_ELSE>
                          <div class="col-12">
                        </TMPL_IF>

                        <!-- Name and link (mandatory) -->
                        <h5 class="appname <TMPL_VAR NAME="appid">">
                          <TMPL_VAR NAME="appname">
                        </h5>

                        <!-- Description (optional) -->
                        <TMPL_IF NAME="appdesc">
                          <p class="appdesc <TMPL_VAR NAME="appid"> card-subtitle mb-2 text-muted">
                            <TMPL_VAR NAME="appdesc">
                          </p>
                        </TMPL_IF>

                          </div>
                        </div>
                        </a>

                      </div>
                      </div>


                    <!-- End of applications loop -->
                    </TMPL_LOOP>
                    </div>

                  </div>
                  </TMPL_IF>

                </div>

              <!-- End of categories loop -->
            </TMPL_IF>
          </TMPL_LOOP>
          </TMPL_IF>
        </div>
      </TMPL_IF>

      <TMPL_IF NAME="ChangePassword">
        <div id="password">
            <div class="card border-secondary">
              <div class="card-header bg-secondary">
              <h4 class="card-title" trspan="changePwd">Change your password</h4>
              </div>
              <div class="card-body">
              <TMPL_INCLUDE NAME="password.tpl">
              </div>
            </div>
        </div>
      </TMPL_IF>

      <TMPL_IF NAME="LoginHistory">
        <div id="loginHistory">
            <TMPL_IF NAME="SUCCESS_LOGIN">
            <div class="card border-secondary mb-3">
              <div class="card-header bg-secondary">
              <h4 class="card-title" trspan="lastLogins">Last logins</h4>
              </div>
              <div class="card-body">
              <TMPL_VAR NAME="SUCCESS_LOGIN">
              </div>
            </div>
            </TMPL_IF>
            <TMPL_IF NAME="FAILED_LOGIN">
            <div class="card border-secondary">
              <div class="card-header bg-secondary">
              <h4 class="card-title" trspan="lastFailedLogins">Last failed logins</h4>
              </div>
              <div class="card-body">
              <TMPL_VAR NAME="FAILED_LOGIN">
              </div>
            </div>
            </TMPL_IF>
        </div>
      </TMPL_IF>

      <TMPL_IF NAME="OidcConsents">
        <div id="oidcConsents">
            <div class="card border-secondary">
              <div class="card-header bg-secondary">
              <h4 class="card-title" trspan="oidcConsentsFull">OpenID-Connect Consents</h4>
              </div>
              <div class="card-body">
              <TMPL_VAR NAME="OIDC_CONSENTS">
              </div>
            </div>
        </div>
      </TMPL_IF>

      <TMPL_IF NAME="Logout">
        <div id="logout">
          <div class="card border-secondary">
            <div class="card-header bg-secondary">
              <h4 class="card-title" trspan="areYouSure">Are you sure ?</h4>
            </div>
            <div class="card-body buttons">
            <a href="<TMPL_VAR NAME="LOGOUT_URL">" class="btn btn-primary" role="button">
              <span class="fa fa-check-circle"></span>
              <span trspan="imSure">I'm sure</span>
            </a>
            </div>
          </div>
        </div>
      </TMPL_IF>

      <TMPL_IF NAME="_PLUGIN">
        <div id="<TMPL_VAR NAME="_PLUGIN_ID">">
        <TMPL_VAR NAME="_PLUGIN_HTML">
        </div>
      </TMPL_IF>
    </TMPL_LOOP>

  </div>

</main>

<TMPL_IF NAME="PING">
<!-- Keep session alive -->
</TMPL_IF>

<TMPL_INCLUDE NAME="footer.tpl">
