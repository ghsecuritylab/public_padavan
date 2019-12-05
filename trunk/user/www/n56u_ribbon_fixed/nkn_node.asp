<!DOCTYPE html>
<html>

<head>
    <title><#Web_Title#> - <#menu8#> : <#NKN_Node#></title>
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
            init_itoggle('nkn_enable', change_nkn_enabled);

            $j("#tabs a").click(function() {
                switchPage(this.id);
                return false;
            });

            $j("#tab_nkn_node").click(function() {
                var newHash = $j(this).attr('href').toLowerCase();
                showTab(newHash);
                return false;
            });
        });

        function switchPage(id) {
            if (id == "tab_nkn_info")
                location.href = "/nkn_info.asp";
            else if(id == "tab_nkn_logs")
		location.href = "/nkn_logs.asp";
            else if(id == "tab_nkn_wallet")
		location.href = "/nkn_wallet.asp";
            else if(id == "tab_nkn_neighbor")
		location.href = "/nkn_neighbor.asp";
            else if(id == "tab_nkn_monitor")
		location.href = "/nkn_monitor.asp";
            return false;
        }
    </script>

    <script>
        <% login_state_hook(); %>

        function initial() {
            show_banner(0);
            show_menu(4, -1, 0);
            show_footer();

            change_nkn_enabled();

            showTab(getHash());

            load_body();
        }

        function applyRule() {
            if (validForm()) {
                showLoading();

                document.form.nkn_wallet_file.value = "";
                document.form.action = "/start_apply.htm";
                document.form.enctype = "application/x-www-form-urlencoded";
                document.form.action_mode.value = " Apply ";
                document.form.current_page.value = "/nkn_node.asp";
                document.form.next_page.value = "";

                document.form.submit();
            }
        }

        function validForm() {
            if (!document.form.nkn_enable[0].checked)
                return true;

            if (document.form.nkn_beneficiary_address.value.length == 36 &&
                    document.form.nkn_beneficiary_address.value.lastIndexOf("NKN") == 0 &&
                    document.form.nkn_wallet_address.value.length == 0) {
                return true;
            }

            if (document.form.nkn_wallet_address.value.length != 36 ||
                    document.form.nkn_wallet_address.value.lastIndexOf("NKN") != 0) {
                alert("<#NKN_WALLET_ADDR_ERR#>");
                document.form.nkn_wallet_address.focus();
                return false;
            }

            if (document.form.nkn_wallet_passwd.value.length < 8) {
                alert("<#NKN_WALLET_PASSWORD_ERR#>");
                document.form.nkn_wallet_passwd.focus();
                return false;
            }

            if (document.form.nkn_beneficiary_address.value.length == 0)
                return true;
            if (document.form.nkn_beneficiary_address.value.length != 36 ||
                    document.form.nkn_beneficiary_address.value.lastIndexOf("NKN") != 0) {
                alert("<#NKN_BENEFICIARY_ADDR_ERR#>");
                document.form.nkn_beneficiary_address.focus();
                return false;
            }

            return true;
        }

        function change_nkn_enabled() {
            var v = document.form.nkn_enable[0].checked;
            showhide_div('tbl_nkn_config', v);
        }

        function checkFileName(obj,ext){
            var fn = obj.value.toUpperCase();
            if(fn == ""){
		alert("<#JS_fieldblank#>");
		obj.focus();
		return false;
            }
            else if(fn.length < 6 ||
			fn.lastIndexOf(ext) < 0 ||
			fn.lastIndexOf(ext) != (fn.length-ext.length)){
		alert("<#Setting_upload_hint#>");
		obj.focus();
		return false;
            }
            return true;
        }

        function set_frm_action_upload(at){
            document.form.action = at;
            document.form.enctype = "multipart/form-data";
            document.form.action_mode.value = "";
        }

        function uploadWallet(){
            if(checkFileName(document.form.nkn_wallet_file, ".JSON")){
		disableCheckChangedStatus();
		set_frm_action_upload("upload_nknwallet.cgi");
		document.form.nkn_wallet_address.value = "";
		document.form.submit();
            }
        }

        var arrHashes = ["cfg"];

        function showTab(curHash) {
            var obj = $('tab_nkn_' + curHash.slice(1));
            if (obj == null || obj.style.display == 'none')
                curHash = '#cfg';
            for (var i = 0; i < arrHashes.length; i++) {
                if (curHash == ('#' + arrHashes[i])) {
                    $j('#tab_nkn_' + arrHashes[i]).parents('li').addClass('active');
                    $j('#wnd_nkn_' + arrHashes[i]).show();
                } else {
                    $j('#wnd_nkn_' + arrHashes[i]).hide();
                    $j('#tab_nkn_' + arrHashes[i]).parents('li').removeClass('active');
                }
            }
            window.location.hash = curHash;
        }

        function getHash() {
            var curHash = window.location.hash.toLowerCase();
            for (var i = 0; i < arrHashes.length; i++) {
                if (curHash == ('#' + arrHashes[i]))
                    return curHash;
            }
            return ('#' + arrHashes[0]);
        }

        function openLink(s) {
            var link_params = "toolbar=yes,location=yes,directories=no,status=yes,menubar=yes,scrollbars=yes,resizable=yes,copyhistory=no,width=640,height=480";
            var tourl = "https://wallet.nkn.org/wallet/create";
            link = window.open(tourl, "NKNCreateLink", link_params);
            if (!link.opener) link.opener = self;
        }

        function openWallet(s) {
            var link_params = "toolbar=yes,location=yes,directories=no,status=yes,menubar=yes,scrollbars=yes,resizable=yes,copyhistory=no,width=640,height=480";
            var tourl = "https://explorer.nknx.org/addresses/" + document.form.nkn_wallet_address.value;
            link = window.open(tourl, "NKNWalletLink", link_params);
            if (!link.opener) link.opener = self;
        }

        function openBeneficiary(s) {
            var link_params = "toolbar=yes,location=yes,directories=no,status=yes,menubar=yes,scrollbars=yes,resizable=yes,copyhistory=no,width=640,height=480";
            var tourl = "https://explorer.nknx.org/addresses/" + document.form.nkn_beneficiary_address.value;
            link = window.open(tourl, "NKNBeneficiaryLink", link_params);
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
                <div class="span3">
                    <center>
                        <div id="logo"></div>
                    </center>
                </div>
                <div class="span9">
                    <div id="TopBanner"></div>
                </div>
            </div>
        </div>

        <br>

        <div id="Loading" class="popup_bg"></div>

        <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0" style="position: absolute;"></iframe>

        <form method="post" action="/start_apply.htm" name="form" id="ruleForm" target="hidden_frame">
            <input type="hidden" name="current_page" value="nkn_node.asp">
            <input type="hidden" name="next_page" value="">
            <input type="hidden" name="next_host" value="">
            <input type="hidden" name="action_mode" value="">
            <input type="hidden" name="sid_list" value="LANHostConfig;">

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
                        <!--Body content-->
                        <div class="row-fluid">
                            <div class="span12">
                                <div class="box well grad_colour_dark_blue">
                                    <h2 class="box_head round_top"><#menu8#> - <#NKN_Node#></h2>
                                    <div class="round_bottom">
                                        <div class="row-fluid">
                                            <div id="tabMenu" class="submenuBlock"></div>

                                            <div style="margin-bottom: -6px;">
                                                <ul id="tabs" class="nav nav-tabs">
                                                    <li class="active">
                                                        <a href="javascript:void(0)" id="tab_nkn_node">
                                                            <#NKN_Node#>
                                                        </a>
                                                    </li>
                                                    <li>
                                                        <a href="javascript:void(0)" id="tab_nkn_info">
                                                            <#NKN_Info#>
                                                        </a>
                                                    </li>
                                                    <li>
                                                        <a href="javascript:void(0)" id="tab_nkn_neighbor">
                                                            <#NKN_Neighbor#>
                                                        </a>
                                                    </li>
                                                    <li>
                                                        <a href="javascript:void(0)" id="tab_nkn_monitor">
                                                            <#NKN_MONITOR#>
                                                        </a>
                                                    </li>
                                                    <li>
                                                        <a href="javascript:void(0)" id="tab_nkn_logs">
                                                            <#NKN_Logs#>
                                                        </a>
                                                    </li>
                                                    <li>
                                                        <a href="javascript:void(0)" id="tab_nkn_wallet">
                                                            <#NKN_Wallet#>
                                                        </a>
                                                    </li>
                                                </ul>
                                            </div>

                                            <div id="wnd_nkn_cfg">
                                                <div class="alert alert-info" style="margin: 10px;">
                                                    <#NKN_Intro#>
                                                </div>
                                                <table class="table">
                                                    <tr>
                                                        <th width="50%" style="padding-bottom: 0px; border-top: 0 none;">
                                                            <#NKN_Enable#>
                                                        </th>
                                                        <td style="padding-bottom: 0px; border-top: 0 none;">
                                                            <div class="main_itoggle">
                                                                <div id="nkn_enable_on_of">
                                                                    <input type="checkbox" id="nkn_enable_fake" <% nvram_match_x( "", "nkn_enable", "1", "value=1 checked"); %>
                                                                    <% nvram_match_x("", "nkn_enable", "0", "value=0"); %>>
                                                                </div>
                                                            </div>
                                                            <div style="position: absolute; margin-left: -10000px;">
                                                                <input type="radio" name="nkn_enable" id="nkn_enable_1" class="input" value="1" onclick="change_nkn_enabled();" <% nvram_match_x( "", "nkn_enable", "1", "checked"); %>>
                                                                <#checkbox_Yes#>
                                                                    <input type="radio" name="nkn_enable" id="nkn_enable_0" class="input" value="0" onclick="change_nkn_enabled();" <% nvram_match_x( "", "nkn_enable", "0", "checked"); %>>
                                                                    <#checkbox_No#>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </table>
                                                <table class="table" id="tbl_nkn_config" style="display:none">
                                                    <tr>
                                                        <th colspan="2" style="background-color: #E3E3E3;">
                                                            <#NKN_Base#>
                                                        </th>
                                                    </tr>
                                                    <tr id="row_nkn_wallet_upload">
                                                        <th>
                                                            <#NKN_WALLET_UPLOAD#>
                                                        </th>
                                                        <td>
                                                            <input name="nkn_wallet_file" id="nkn_wallet_file" type="file" size="36" />
                                                        </td>
                                                    </tr>
                                                    <tr id="row_nkn_wallet_upload2">
                                                        <th style="border-top: 0 none; padding-top: 0px;"></th>
                                                        <td style="border-top: 0 none; padding-top: 0px;">
                                                            <input name="nkn_wallet_upload" class="btn btn-info" style="width: 219px;" onclick="uploadWallet();" type="button" value="<#CTL_upload#>"/>
                                                            &nbsp;<a href="javascript:openLink('x_NKNCreate')" class="label label-success" name="x_NKNCreate_link"><#NKN_Create_Link#></a>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_WALLET_ADDR#>
                                                        </th>
                                                        <td>
                                                            <input type="text" class="input" size="40" name="nkn_wallet_address" id="nkn_wallet_address" value="<% nvram_get_x(" ","nkn_wallet_address"); %>" readonly="1">
                                                            &nbsp;<a href="javascript:openWallet('x_NKNWallet')" class="label label-info" name="x_NKNWallet_link"><#NKN_Wallet_Link#></a>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_WALLET_PASSWORD#>
                                                        </th>
                                                        <td>
                                                            <div class="input-append">
                                                                <input type="password" maxlength="20" class="input" size="32" name="nkn_wallet_passwd" id="nkn_wallet_passwd" style="width: 175px;" value="<% nvram_get_x(" ","nkn_wallet_passwd"); %>"/>
                                                                <button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('nkn_wallet_passwd')"><i class="icon-eye-close"></i></button>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <th colspan="2" style="background-color: #E3E3E3;">
                                                            <#NKN_BENEFICIARY_INFO#>
                                                        </th>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_BENEFICIARY_ADDR#>
                                                        </th>
                                                        <td>
                                                            <input type="text" class="input" size="40" name="nkn_beneficiary_address" id="nkn_beneficiary_address" value="<% nvram_get_x(" ","nkn_beneficiary_address"); %>">
                                                            &nbsp;<a href="javascript:openBeneficiary('x_NKNBeneficiary')" class="label label-info" name="x_NKNBeneficiary_link"><#NKN_Beneficiary_Link#></a>
                                                        </td>
                                                    </tr>
                                                </table>
                                                <table class="table">
                                                    <tr>
                                                        <td style="border: 0 none; padding: 0px;">
                                                            <center>
                                                                <input name="button" type="button" class="btn btn-primary" style="width: 219px" onclick="applyRule();" value="<#CTL_apply#>" />
                                                            </center>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
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