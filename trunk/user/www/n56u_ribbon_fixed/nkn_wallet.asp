<!DOCTYPE html>
<html>

<head>
    <title><#Web_Title#> - <#menu8#> : <#NKN_Wallet#></title>
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
    <script type="text/javascript" src="/popup.js"></script>
    <script>
        var $j = jQuery.noConflict();

        $j(document).ready(function() {

            $j("#tabs a").click(function() {
                switchPage(this.id);
                return false;
            });

            $j('#transfer_nkn').click(function(){
                var $button = $j(this);
                send_transfer_action($button.prop('id'), $button);
                return false;
            });

            $j("#tab_nkn_wallet").click(function() {
                var newHash = $j(this).attr('href').toLowerCase();
                showTab(newHash);
                return false;
            });
        });

        function switchPage(id) {
            if (id == "tab_nkn_node")
                location.href = "/nkn_node.asp";
            else if(id == "tab_nkn_info")
		location.href = "/nkn_info.asp";
            else if(id == "tab_nkn_logs")
		location.href = "/nkn_logs.asp";
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

            showTab(getHash());

            load_body();
        }

        function set_frm_action(at){
            document.form.action = at;
            document.form.enctype = "application/x-www-form-urlencoded";
            document.form.action_mode.value = "";
        }

        function refreshBalance(){
            $('refresh_balance').disabled = true;
            $("nkn_wallet_balance").innerHTML = "***";
            set_frm_action("refresh_balance.cgi");
            document.form.submit();
        }

        function validForm() {
            if (document.form.nkn_transfer_to.value.length != 36 ||
                    document.form.nkn_transfer_to.value.lastIndexOf("NKN") != 0) {
                alert("<#NKN_TRANSFER_TO_ERR#>");
                document.form.nkn_transfer_to.focus();
                return false;
            }

            if (document.form.nkn_transfer_amount.value == "") {
                alert("<#NKN_TRANSFER_AMOUNT_ERR#>");
                document.form.nkn_transfer_amount.focus();
                return false;
            }

            if (document.form.nkn_transfer_fee.value == "") {
                alert("<#NKN_TRANSFER_FEE_ERR#>");
                document.form.nkn_transfer_fee.focus();
                return false;
            }

            if (document.form.nkn_transfer_passwd.value.length < 8) {
                alert("<#NKN_WALLET_PASSWORD_ERR#>");
                document.form.nkn_transfer_passwd.focus();
                return false;
            }

            return true;
        }

        function send_transfer_action(action_id,$button){
        	if(!validForm())
	        	return;

        	$button.val("<#NKN_CTL_transferring#>");
        	$('transfer_nkn').disabled = true;
	        $j.ajax({
		        type: "post",
        		url: "/apply.cgi",
	        	data: {
		        	action_mode: " TransferNKN ",
			        nkn_transfer_to: $('nkn_transfer_to').value,
        			nkn_transfer_amount: $('nkn_transfer_amount').value,
        			nkn_transfer_fee: $('nkn_transfer_fee').value,
	        		nkn_transfer_passwd: $('nkn_transfer_passwd').value
		        },
        		dataType: "json",
	        	error: function(xhr) {
		        	alert("<#NKN_Transfer_failed#>");
	        	},
		        success: function(response) {
	        		$button.val("<#NKN_CTL_transfer#>");
			        var sys_result = (response != null && typeof response === 'object' && "sys_result" in response)
				        ? response.sys_result : -1;
        			if(sys_result == 0) {
	        			$('nkn_transfer_passwd').value = "";
	        			alert("<#NKN_Transfer_successful#>");
        			} else
			        	alert("<#NKN_Transfer_failed#>");
		        	$('transfer_nkn').disabled = false;
		        }
	        });
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
            <input type="hidden" name="current_page" value="nkn_wallet.asp">
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
                                    <h2 class="box_head round_top"><#menu8#> - <#NKN_Wallet#></h2>
                                    <div class="round_bottom">
                                        <div class="row-fluid">
                                            <div id="tabMenu" class="submenuBlock"></div>

                                            <div style="margin-bottom: -6px;">
                                                <ul id="tabs" class="nav nav-tabs">
                                                    <li>
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
                                                    <li class="active">
                                                        <a href="javascript:void(0)" id="tab_nkn_wallet">
                                                            <#NKN_Wallet#>
                                                        </a>
                                                    </li>
                                                </ul>
                                            </div>

                                            <div id="wnd_nkn_wallet">
                                                <table class="table" id="tbl_nkn_balance">
                                                    <tr>
                                                        <th colspan="2" style="background-color: #E3E3E3;">
                                                            <#NKN_Base#>
                                                        </th>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_WALLET_ADDR#>
                                                        </th>
                                                        <td colspan="3"><% nvram_get_x(" ","nkn_wallet_address"); %></td>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_WALLET_BALANCE#>
                                                        </th>
                                                        <td colspan="3"><span id="nkn_wallet_balance"><% nvram_dump("nknbala.log", ""); %></span>
                                                        &nbsp;<input type="button" name="refresh_balance" id="refresh_balance" maxlength="15" size="15" class="btn btn-info" style="max-width: 94px;" onclick="refreshBalance();" value="<#CTL_refresh#>"/>
                                                        </td>
                                                    </tr>
                                                </table>
                                                <table class="table" id="tbl_nkn_transfer">
                                                    <tr>
                                                        <th colspan="2" style="background-color: #E3E3E3;">
                                                            <#NKN_Transfer#>
                                                        </th>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_TRANSFER_TO#>
                                                        </th>
                                                        <td colspan="3"><input type="text" class="input" style="width: 300px;" name="nkn_transfer_to" id="nkn_transfer_to"></td>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_TRANSFER_AMOUNT#>
                                                        </th>
                                                        <td colspan="3"><input type="text" class="input" size="40" name="nkn_transfer_amount" id="nkn_transfer_amount" onkeypress="return is_number_period(this,event);"></td>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_TRANSFER_FEE#>
                                                        </th>
                                                        <td colspan="3"><input type="text" class="input" size="40" name="nkn_transfer_fee" id="nkn_transfer_fee" onkeypress="return is_number_period(this,event);"></td>
                                                    </tr>
                                                    <tr>
                                                        <th>
                                                            <#NKN_WALLET_PASSWORD#>
                                                        </th>
                                                        <td colspan="3">
                                                            <div class="input-append">
                                                                <input type="password" maxlength="20" class="input" size="32" name="nkn_transfer_passwd" id="nkn_transfer_passwd" style="width: 175px;"/>
                                                                <button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('nkn_transfer_passwd')"><i class="icon-eye-close"></i></button>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </table>
                                                <table class="table">
                                                    <tr>
                                                        <td style="border: 0 none; padding: 0px;">
                                                            <center>
                                                                <input type="button" name="transfer_nkn" id="transfer_nkn" class="btn btn-primary" style="width: 219px" value="<#NKN_CTL_transfer#>" />
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