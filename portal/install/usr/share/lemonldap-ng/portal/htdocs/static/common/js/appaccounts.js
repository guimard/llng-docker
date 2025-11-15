(function () {
  'use strict';

  var token, apiBase;
  doNothing = function doNothing(e) {
    console.debug('Ignored error', e);
  };
  reportErr = function reportErr(j, status, err) {
    if (j.status > 200 && j.responseText) {
      try {
        var text = JSON.parse(j.responseText);
        if (text.error === 'Too many accounts') {
          alert('You reached the maximum allowed accounts');
          return load();
        } else if (text.error) {
          $('#errmsg').text(text.error);
        }
      } catch (e) {
        console.error(e);
        $('#errmsg').text(err);
      }
    }
    console.error(j.responseText);
    console.log(j.status);
    display('#none');
  };
  addDevice = function addDevice() {
    ask('accountName', 'createAccount').then(function (optDevName) {
      _addDevice(optDevName);
    }).catch(doNothing);
  };
  _addDevice = function _addDevice(name) {
    $.ajax({
      type: 'POST',
      url: apiBase + 'add',
      data: JSON.stringify({
        token: token,
        name: name
      }),
      contentType: 'application/json',
      dataType: 'json',
      success: function success(data) {
        displayPwd(data);
      },
      error: reportErr
    });
    return false;
  };
  ask = function ask(question, buttonLabel, noValue) {
    return new Promise(function (resolve, reject) {
      $('#promptmsg').text(window.translate(question));
      $('#promptok').text(window.translate(buttonLabel ? buttonLabel : 'validate'));
      $('#promptok').click(function () {
        var val = $('#promptval').val();
        if (!noValue && !val) return false;
        resolve($('#promptval').val());
      });
      $('#promptcancel').click(function () {
        load();
        reject();
      });
      display('#prompt');
      if (noValue) {
        $('#promptinput').hide();
      } else {
        $('#promptinput').show();
        $('#promptval').focus();
      }
    });
  };
  copy = function copy(data) {
    navigator.clipboard.writeText(data);
    $('#copied').fadeIn();
    setTimeout(function () {
      $('#copied').fadeOut();
    }, 700);
  };
  displayPwd = function displayPwd(data) {
    $('#newpwd').html("\n<h6 class=\"text-xl font-bold text-center mb-8\">Courriel: ".concat(data.mail, "</h6>\n<h6 class=\"text-xl font-bold text-center mb-8\">Identifiant: ").concat(data.uid, " <button style=\"display:inline;\" class=\"cursor-pointer hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 rounded-xl bg-blue-700 h-[48px] w-[48px]\"><img src=\"/static/cnb/img/copy.png\" onclick=\"copy('").concat(data.uid, "')\" style=\"display:inline;\" width=\"25px\"/></button></h6>\n<h6 class=\"text-xl font-bold text-center mb-8\">Mot de passe: <span id=\"escaped\"></span> <button style=\"display:inline;\" class=\"cursor-pointer hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 rounded-xl bg-blue-700 h-[48px] w-[48px]\"><img src=\"/static/cnb/img/copy.png\" onclick=\"copy('").concat(data.pwd, "')\" style=\"display:inline;\" width=\"25px\"/></button></h6>\n  "));
    $('#escaped').text(data.pwd);
    display('#displaypwd');
  };
  delDevice = function delDevice(dev) {
    ask('delAppAccount', 'confirm', 1).then(function () {
      console.debug('Call _device', dev);
      _delDevice(dev);
    }).catch(doNothing);
  };
  _delDevice = function _delDevice(dev) {
    $.ajax({
      type: 'POST',
      url: apiBase + 'del',
      data: JSON.stringify({
        token: token,
        uid: dev
      }),
      contentType: 'application/json',
      dataType: 'json',
      success: function success(data) {
        load();
      },
      error: reportErr
    });
    return false;
  };
  load = function load() {
    $('#newpwd').html('');
    display('#displaylist');
    $.ajax({
      url: apiBase + 'list',
      dataType: 'json',
      success: function success(data) {
        var h = '';
        data.forEach(function (dev) {
          var duid = dev.uid.replace(/\W/g, '');
          h += deviceTemplate(dev.name ? dev.name : dev.uid, duid);
        });
        $('#deviceslist').html(h);
        data.forEach(function (dev) {
          var duid = dev.uid.replace(/\W/g, '');
          console.debug('Add remove event on #remove' + dev.uid);
          $('#remove' + duid).click(function () {
            delDevice(dev.uid);
          });
        });
      },
      error: reportErr
    });
  };
  display = function display(name) {
    ['#displaypwd', '#prompt', '#displaylist'].forEach(function (id) {
      name === id ? $(id).show() : $(id).hide();
    });
  };
  $(window).on('load', function () {
    token = $('#token').val();
    console.debug('token', token);
    apiBase = location.href.replace(/\?.*$/, '') + '/';
    $('#adddevice').click(addDevice);
    $('#validatedevice').click(load);
    load();
  });
  deviceTemplate = function deviceTemplate(name, uid) {
    return "<div id=\"list\" class=\"lemonldapp-ng__body-menu-item bg-slate-100 flex flex-col p-8 rounded-xl gap-2 md:gap-4\">\n  <h6 class=\"text-xl font-bold text-center mb-8\">Compte \"".concat(name, "\"</h6>\n  <button id=\"remove").concat(uid, "\" class=\"cursor-pointer h-[48px] hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600 rounded-xl bg-red-700 text-white p-1 py-2 md:p-2 md:py-3 w-3/3 md:w-3/3\">\n     Supprimer\n  </button>\n</div>");
  };

})();
