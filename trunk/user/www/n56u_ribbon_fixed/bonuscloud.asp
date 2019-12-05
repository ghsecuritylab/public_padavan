<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#menu7#></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {
	init_itoggle('bxc_enable', change_bxc_enabled);

	$j("#tab_bxc_cfg").click(function(){
		var newHash = $j(this).attr('href').toLowerCase();
		showTab(newHash);
		return false;
	});
});

</script>

<script>
<% login_state_hook(); %>
<% wanlink(); %>

function initial(){
	show_banner(0);
	show_menu(3, -1, 0);
	show_footer();

	var v = <% nvram_get_x("", "bxc_bounded"); %>;
	showhide_div('col_bxc_state', v);

	$("WANMAC").innerHTML = wanlink_mac();

	change_bxc_enabled();

	showTab(getHash());

	load_body();
}

function applyRule(){
	if(validForm()){
		showLoading();
		
		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/bonuscloud.asp";
		document.form.next_page.value = "";
		
		document.form.submit();
	}
}

function validForm(){
	if (!document.form.bxc_enable[0].checked)
		return true;

	if(document.form.bxc_email.value.length < 6){
		alert("Email address is invalid!");
		document.form.bxc_email.focus();
		return false;
	}

	if(document.form.bxc_bcode.value.length != 41){
		alert("Bcode is invalid!");
		document.form.bxc_bcode.focus();
		return false;
	}

	return true;
}

function change_bxc_enabled() {
	var v = document.form.bxc_enable[0].checked;

	showhide_div('tbl_bxc_config', v);
}

var arrHashes = ["cfg"];

function showTab(curHash){
	var obj = $('tab_bxc_'+curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
		curHash = '#cfg';
	for(var i = 0; i < arrHashes.length; i++){
		if(curHash == ('#'+arrHashes[i])){
			$j('#tab_bxc_'+arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_bxc_'+arrHashes[i]).show();
		}else{
			$j('#wnd_bxc_'+arrHashes[i]).hide();
			$j('#tab_bxc_'+arrHashes[i]).parents('li').removeClass('active');
		}
	}
	window.location.hash = curHash;
}

function getHash(){
	var curHash = window.location.hash.toLowerCase();
	for(var i = 0; i < arrHashes.length; i++){
		if(curHash == ('#'+arrHashes[i]))
			return curHash;
	}
	return ('#'+arrHashes[0]);
}

function openLink(s) {
	var link_params = "toolbar=yes,location=yes,directories=no,status=yes,menubar=yes,scrollbars=yes,resizable=yes,copyhistory=no,width=640,height=480";
	var tourl = "https://console.bonuscloud.io/signUp?refer=5cf91dc0ce2211e8bd3abffcd72ca6c1";
	link = window.open(tourl, "BXCSignupLink", link_params);
	if (!link.opener) link.opener = self;
}

</script>

<style>
    .caption-bold {
        font-weight: bold;
    }
</style>

</head>

<body onload="initial();" onunload="unload_body();">

<div class="wrapper">
    <div class="container-fluid" style="padding-right: 0px">
        <div class="row-fluid">
            <div class="span3"><center><div id="logo"></div></center></div>
            <div class="span9" >
                <div id="TopBanner"></div>
            </div>
        </div>
    </div>

    <br>

    <div id="Loading" class="popup_bg"></div>

    <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0" style="position: absolute;"></iframe>

    <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
    <input type="hidden" name="current_page" value="bonuscloud.asp">
    <input type="hidden" name="next_page" value="">
    <input type="hidden" name="next_host" value="">
    <input type="hidden" name="sid_list" value="LANHostConfig;">
    <input type="hidden" name="group_id" value="">
    <input type="hidden" name="action_mode" value="">
    <input type="hidden" name="action_script" value="">
    <input type="hidden" name="flag" value="">

    <div class="container-fluid">
        <div class="row-fluid">
             <div class="span3">
                <!--Sidebar content-->
                  <!--=====Beginning of Main Menu=====-->
                  <div class="well sidebar-nav side_nav" style="padding: 0px;">
                      <ul id="mainMenu" class="clearfix"></ul>
                      <ul class="clearfix">
                          <li>
                              <div id="subMenu" class="accordion"></div>
                          </li>
                      </ul>
                  </div>
             </div>

             <div class="span9">
                <div class="box well grad_colour_dark_blue">
                    <div id="tabMenu"></div>
                    <h2 class="box_head round_top"><#menu7#></h2>

                    <div class="round_bottom">

                        <div>
                            <ul class="nav nav-tabs" style="margin-bottom: 10px;">
                                <li class="active">
                                    <a id="tab_bxc_cfg" href="#cfg"><#BXC_Node#></a>
                                </li>
                            </ul>
                        </div>

                        <div id="wnd_bxc_cfg">
                            <div class="alert alert-info" style="margin: 10px;"><#BXC_Info#></div>
                            <table class="table">
                                <tr>
                                    <th width="50%" style="padding-bottom: 0px; border-top: 0 none;"><#BXC_Enable#></th>
                                    <td style="padding-bottom: 0px; border-top: 0 none;">
                                        <div class="main_itoggle">
                                            <div id="bxc_enable_on_of">
                                                <input type="checkbox" id="bxc_enable_fake" <% nvram_match_x("", "bxc_enable", "1", "value=1 checked"); %><% nvram_match_x("", "bxc_enable", "0", "value=0"); %>>
                                            </div>
                                        </div>
                                            <div style="position: absolute; margin-left: -10000px;">
                                            <input type="radio" name="bxc_enable" id="bxc_enable_1" class="input" value="1" onclick="change_bxc_enabled();" <% nvram_match_x("", "bxc_enable", "1", "checked"); %>><#checkbox_Yes#>
                                            <input type="radio" name="bxc_enable" id="bxc_enable_0" class="input" value="0" onclick="change_bxc_enabled();" <% nvram_match_x("", "bxc_enable", "0", "checked"); %>><#checkbox_No#>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                            <table class="table" id="tbl_bxc_config" style="display:none">
                                <tr>
                                    <th colspan="2" style="background-color: #E3E3E3;"><#BXC_Base#></th>
                                </tr>
                                <tr>
                                    <th><#BXC_VER#></th>
                                    <td colspan="3"><span id="BXCVER">0.2.2-12p</span></td>
                                </tr>
                                <tr>
                                    <th><#BXC_Email#></th>
                                    <td>
                                        <input type="text" name="bxc_email" class="input" maxlength="64" size="41" value="<% nvram_get_x("", "bxc_email"); %>" onKeyPress="return is_string(this,event);"/>
                                        &nbsp;<a href="javascript:openLink('x_BXCSignup')" class="label label-info" name="x_BXCSignup_link"><#BXC_Signup_Link#></a>
                                    </td>
                                </tr>
                                <tr>
                                    <th><#BXC_Bcode#></th>
                                    <td>
                                       <input type="text" maxlength="41" class="input" size="41" name="bxc_bcode" value="<% nvram_get_x("", "bxc_bcode"); %>" onkeypress="return is_string(this,event);"/>
                                        &nbsp;<span id="col_bxc_state" style="display:none" class="label label-success"><#BXC_Bounded#></span>
                                    </td>
                                </tr>
                                <tr>
                                    <th><#MAC_Address#></th>
                                    <td colspan="3"><span id="WANMAC"></span></td>
                                </tr>
                            </table>
                            <table class="table">
                                <tr>
                                    <td style="border: 0 none; padding: 0px;"><center><input name="button" type="button" class="btn btn-primary" style="width: 219px" onclick="applyRule();" value="<#CTL_apply#>"/></center></td>
                                </tr>
                            </table>
                        </div>

                    </div>
                </div>
             </div>
        </div>
    </div>
    </form>

    <div id="footer"></div>
</div>

</body>
</html>
