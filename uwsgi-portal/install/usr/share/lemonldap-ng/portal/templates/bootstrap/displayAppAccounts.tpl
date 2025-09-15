<TMPL_INCLUDE NAME="header.tpl">

<!--
<main id="menucontent" class="container">
-->

  <div class="lemonldapp-ng__header-action flex flex-row space-x-2 md:space-x-8 flex-nowrap justify-end items-center">
  
    <div class="lemonldapp-ng__header-account-info bg-white rounded-full flex flex-row flex-nowrap justify-between items-center p-1">
      <strong class="px-3 text-xs md:text-sm"><TMPL_VAR NAME="AUTH_USER"></strong>
    </div>
  </div>
</div>

<div class="lemonldapp-ng__header space-y-4 md:space-y-0">
  <TMPL_IF NAME="AUTH_ERROR">
    <div class="lemonldapp-ng__header-account-info rounded-full message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span id="errmsg" trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span></div>
  <TMPL_ELSE>
    <div class="lemonldapp-ng__header-account-info rounded-full message message-positive alert">
      <span trspan="accountsList"></span>
    </div>
  </TMPL_IF>
</div>
<div id="displaylist" class="lemonldapp-ng__body flex flex-col md:flex-row justify-start items-stretch sm:p-2 md:p-8 space-y-4 md:space-x-4 md:space-y-0 lg:max-w-[90vw]">
  <input type="hidden" id="token" name="token" value="<TMPL_VAR NAME="TOKEN">" />
  <div id="deviceslist" class="lemonldapp-ng__body-menu bg-white p-4 md:p-8 rounded-3xl grid gap-4 grid-cols-1 md:w-2/3">
    <!-- Modified by script -->
  </div>
  <div class="lemonldapp-ng__body-history bg-white rounded-3xl md:w-1/3 py-8 px-1">
    <center>
      <button id="adddevice" class="cursor-pointer h-[48px] hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 rounded-xl bg-blue-700 text-white p-1 py-2 md:p-2 md:py-3 w-[140px] md:w-[180px]" trspan="addAccount">
      </button>
    </center>
  </div>
</div>

<div id="displaypwd" class="lemonldapp-ng__body flex flex-col md:flex-row justify-start items-stretch sm:p-2 md:p-8 space-y-4 md:space-x-4 md:space-y-0 lg:max-w-[90vw]">
  <div class="lemonldapp-ng__body-menu bg-white p-4 md:p-8 rounded-3xl grid gap-4 grid-cols-1 md:w-2/3">
    <h6 class="text-xl font-bold text-center mb-8" trspan="newAppAccount"></h6>
    <div id="newpwd" class="lemonldapp-ng__body-menu-item bg-slate-100 flex flex-col p-8 rounded-xl gap-2 md:gap-4">
    </div>
  </div>
  <div class="lemonldapp-ng__body-history bg-white rounded-3xl md:w-1/3 py-8 px-1">
    <center>
      <button id="validatedevice" class="cursor-pointer h-[48px] hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 rounded-xl bg-blue-700 text-white p-1 py-2 md:p-2 md:py-3 w-[140px] md:w-[180px]" trspan="validate">
      </button>
    </center>
  </div>
  <div style="display: none;position:absolute;top:50%;left:50%;background-color:yellow;padding:20px;margin-right:-50%;transform:translate(-50%,-50%);border-radius:30px;font-style:italic;font-weight:bold;" id="copied" trspan="copied"></div>
</div>

<div id="prompt" class="lemonldapp-ng__body flex flex-col md:flex-row justify-start items-stretch sm:p-2 md:p-8 space-y-4 md:space-x-4 md:space-y-0 lg:max-w-[90vw]">
  <div class="lemonldapp-ng__body-menu bg-white p-4 md:p-8 rounded-3xl grid gap-4 grid-cols-1 md:w-2/3">
    <h6 id="promptmsg"  class="text-xl font-bold text-center mb-8"></h6>
    <div id="promptinput" class="lemonldapp-ng__body-menu-item bg-slate-100 flex flex-col p-8 rounded-xl gap-2 md:gap-4">
      <label id="promptvallabel" trspan="accountName"></label>
      <input id="promptval" />
    </div>
    <center>
      <button id="promptok" class="cursor-pointer h-[48px] hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 rounded-xl bg-blue-700 text-white p-1 py-2 md:p-2 md:py-3 w-[140px] md:w-[180px]" trspan="validate">
      </button>
      <button id="promptcancel" class="cursor-pointer h-[48px] hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600 rounded-xl bg-red-700 text-white p-1 py-2 md:p-2 md:py-3 w-[140px] md:w-[180px]" trspan="cancel">
      </button>
    </center>
  </div>
  <div class="lemonldapp-ng__body-history bg-white rounded-3xl md:w-1/3 py-8 px-1">
  </div>
</div>

<div id="logout">
  <div class="buttons">
  <TMPL_IF NAME="MSG"><TMPL_VAR NAME="MSG"></TMPL_IF>
    <a href="<TMPL_VAR NAME="PORTAL_URL"><TMPL_IF NAME="AUTH_URL">&url=<TMPL_VAR NAME="AUTH_URL"></TMPL_IF>">
      <button
       class="cursor-pointer h-[48px] hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 rounded-xl bg-blue-700 text-white p-1 py-2 md:p-2 md:py-3 w-[140px] md:w-[180px]"
      >
      <span class="fa fa-home"></span>
      <span trspan="goToPortal">Go to portal</span>
      </button>
    </a>
  </div>
</div>
<!--
</main>
-->

<script type="text/javascript" src="/static/common/appaccounts.js"></script>

<TMPL_INCLUDE NAME="footer.tpl">
