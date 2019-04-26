<!DOCTYPE html>
<html>

<head>
    <title><#Web_Title#> - <#menu8#> : <#NKN_Neighbor#></title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="-1">

    <link rel="shortcut icon" href="images/favicon.ico">
    <link rel="icon" href="images/favicon.png">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">

    <script type="text/javascript" src="/jquery.js"></script>
    <script type="text/javascript" src="/state.js"></script>
    <script type="text/javascript" src="/popup.js"></script>
    <script>
        var $j = jQuery.noConflict();

        $j(document).ready(function() {
            $j("#tabs a").click(function() {
                switchPage(this.id);
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
            else if(id == "tab_nkn_wallet")
		location.href = "/nkn_wallet.asp";
            return false;
        }
    </script>

    <script>
        <% login_state_hook(); %>

        function initial() {
            show_banner(0);
            show_menu(4, -1, 0);
            show_footer();
        }
    </script>

    <style>
        .caption-bold {
            font-weight: bold;
        }
    </style>

</head>

<body onload="initial();">

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
                                <h2 class="box_head round_top"><#menu8#> - <#NKN_Neighbor#></h2>
                                <div class="round_bottom">
                                    <div class="row-fluid">
                                        <div id="tabMenu" class="submenuBlock"></div>
                                        <div style="margin-bottom: -16px;">
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
                                                <li class="active">
                                                    <a href="javascript:void(0)" id="tab_nkn_neighbor">
                                                        <#NKN_Neighbor#>
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
                                        <table width="100%" cellpadding="4" cellspacing="0" class="table">
                                            <tr>
                                                <td style="border-top: 0 none; padding-bottom: 0px;">
                                                    <textarea rows="23" class="span12" style="height:403px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off"><% nvram_dump("nknneig.log", ""); %></textarea>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="text-align: right; padding-bottom: 0px;">
                                                    <input type="button" onClick="location.href=location.href" value="<#CTL_refresh#>" class="btn btn-primary" style="width: 219px;">
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

        <div id="footer"></div>
    </div>

</body>

</html>