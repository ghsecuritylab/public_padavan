<!DOCTYPE html>
<html>

<head>
    <title><#Web_Title#> - <#menu8#> : <#NKN_MONITOR#></title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="-1">

    <link rel="shortcut icon" href="images/favicon.ico">
    <link rel="icon" href="images/favicon.png">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">

    <script type="text/javascript" src="/jquery.js"></script>
    <script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="/bootstrap/js/highcharts.js"></script>
    <script type="text/javascript" src="/bootstrap/js/highcharts_theme.js"></script>
    <script type="text/javascript" src="/state.js"></script>
    <script type="text/javascript" src="/popup.js"></script>
    <script>
        var $j = jQuery.noConflict();
        var nknmon = {
            CPU: 0,
            MEMORY: 0,
            CONNECTIONS: 0
        };

        var nknChart;
        var nkn_cpu;
        var nkn_mem;
        var nkn_con;
        var nkn_history;

        var updateAvgLen = 5;

        var idTimerPoll = 0;

        var nkn_chart_rt = {
            chart: {
                renderTo: 'nkn_chart',
                zoomType: 'x',
                spacingRight: 15
            },
            title: {
                text: '<#NKN_MONITOR_TITLE#>',
                align: 'left'
            },
            xAxis: {
                type: 'datetime',
                minRange: 10 * 1000,
                title: {
                    text: null
                },
                labels: {
                    format: '{value:%H:%M:%S}'
                }
            },
            yAxis: {
                min: 0,
                minRange: 100,
                opposite: false,
                startOnTick: false,
                showFirstLabel: false
            },
            plotOptions: {
                series: {
                    animation: false
                },
                areaspline: {
                    lineWidth: 1,
                    fillOpacity: 0.3
                }
            },
            legend: {
                enabled: true,
                verticalAlign: 'top',
                floating: true,
                align: 'right'
            },
            rangeSelector: {
                buttons: [{
                    count: 1,
                    type: 'minute',
                    text: '1M'
                }, {
                    count: 5,
                    type: 'minute',
                    text: '5M'
                }, {
                    count: 15,
                    type: 'minute',
                    text: '15M'
                }, {
                    type: 'all',
                    text: 'All'
                }],
                inputEnabled: false,
                selected: 1
            },
            tooltip: {
                xDateFormat: '%H:%M:%S'
            },
            series: [{
                type: 'areaspline',
                name: '<#NKN_CPU#>',
                color: '#FF9000',
                gapSize: 5,
                threshold: null,
                data: (prepare_array_chart)(),
                tooltip: {
                    valueSuffix: ' %'
                }
            }, {
                type: 'areaspline',
                name: '<#NKN_MEMORY#>',
                color: '#00CC00',
                gapSize: 5,
                threshold: null,
                data: (prepare_array_chart)(),
                tooltip: {
                    valueSuffix: ' MB'
                }
            }, {
                type: 'areaspline',
                name: '<#NKN_CON#>',
                color: '#003EBA',
                gapSize: 5,
                threshold: null,
                data: (prepare_array_chart)()
            }]
        };

        Highcharts.locale = {
            global: {
                useUTC: false
            },
            lang: {
                months: ['<#MF_Jan#>', '<#MF_Feb#>', '<#MF_Mar#>', '<#MF_Apr#>', '<#MF_May#>', '<#MF_Jun#>', '<#MF_Jul#>', '<#MF_Aug#>', '<#MF_Sep#>', '<#MF_Oct#>', '<#MF_Nov#>', '<#MF_Dec#>'],
                shortMonths: ['<#MS_Jan#>', '<#MS_Feb#>', '<#MS_Mar#>', '<#MS_Apr#>', '<#MS_May#>', '<#MS_Jun#>', '<#MS_Jul#>', '<#MS_Aug#>', '<#MS_Sep#>', '<#MS_Oct#>', '<#MS_Nov#>', '<#MS_Dec#>'],
                weekdays: ['<#WF_Sun#>', '<#WF_Mon#>', '<#WF_Tue#>', '<#WF_Wed#>', '<#WF_Thu#>', '<#WF_Fri#>', '<#WF_Sat#>'],
                rangeSelectorZoom: '<#HSTOCK_Zoom#>'
            }
        };

        Highcharts.setOptions(Highcharts.locale);

        function invoke_timer(s) {
            idTimerPoll = setTimeout('load_nknmon()', s * 1000);
        }

        $j(document).ready(function() {
            $j("#tabs a").click(function() {
                switchPage(this.id);
                return false;
            });
            nknChart = new Highcharts.StockChart(nkn_chart_rt);
            invoke_timer(2);
        });

        function initial() {
            show_banner(0);
            show_menu(4, -1, 0);
            show_footer();

            initTab();
            calc_nkn();
        }

        function initTab() {
            E('cpu-sel').style.background = '#FF9000';
            E('mem-sel').style.background = '#00CC00';
            E('con-sel').style.background = '#003EBA';

            E('cpu-current').innerHTML = '0%';
            E('cpu-avg').innerHTML = '0%';
            E('cpu-max').innerHTML = '0%';

            E('mem-current').innerHTML = '0%';
            E('mem-avg').innerHTML = '0%';
            E('mem-max').innerHTML = '0%';

            E('con-current').innerHTML = '0';
            E('con-avg').innerHTML = '0';
            E('con-max').innerHTML = '0';
        }

        function calc_nkn() {
            var c, h, t, i, j;
            var x = (new Date()).getTime();

            x = parseInt(x / 1000) * 1000;

            c = nknmon;
            h = nkn_history;
            if (nkn_cpu === undefined)
                nkn_cpu = prepare_array(x);
            if (nkn_mem === undefined)
                nkn_mem = prepare_array(x);
            if (nkn_con === undefined)
                nkn_con = prepare_array(x);

            if (h === undefined) {
                nkn_history = {};
                h = nkn_history;
                h.CPU = [];
                h.MEMORY = [];
                h.CONNECTIONS = [];
                h.cpu_avg = 0;
                h.mem_avg = 0;
                h.con_avg = 0;
                h.cpu_max = 0;
                h.mem_max = 0;
                h.con_max = 0;
                for (j = updateAvgLen; j > 0; --j) {
                    h.CPU.push(0);
                    h.MEMORY.push(0);
                    h.CONNECTIONS.push(0);
                }
            }

            h.CPU.splice(0, 1);
            h.CPU.push(c.CPU);
            if (c.CPU > h.cpu_max)
                h.cpu_max = c.CPU;
            t = 0;
            for (j = (h.CPU.length - updateAvgLen); j < h.CPU.length; ++j)
                t += h.CPU[j];
            h.cpu_avg = t / updateAvgLen;

            h.MEMORY.splice(0, 1);
            h.MEMORY.push(c.MEMORY);
            if (c.MEMORY > h.mem_max)
                h.mem_max = c.MEMORY;
            t = 0;
            for (j = (h.MEMORY.length - updateAvgLen); j < h.MEMORY.length; ++j)
                t += h.MEMORY[j];
            h.mem_avg = t / updateAvgLen;

            h.CONNECTIONS.splice(0, 1);
            h.CONNECTIONS.push(c.CONNECTIONS);
            if (c.CONNECTIONS > h.con_max)
                h.con_max = c.CONNECTIONS;
            t = 0;
            for (j = (h.CONNECTIONS.length - updateAvgLen); j < h.CONNECTIONS.length; ++j)
                t += h.CONNECTIONS[j];
            h.con_avg = t / updateAvgLen;

            nkn_cpu.push([x, c.CPU]);
            nkn_mem.push([x, c.MEMORY]);
            nkn_con.push([x, c.CONNECTIONS]);

            nknChart.series[0].addPoint([x, c.CPU], false, false);
            nknChart.series[1].addPoint([x, c.MEMORY], false, false);
            nknChart.series[2].addPoint([x, c.CONNECTIONS], false, false);

            updateTab(nkn_history);
        }

        function updateTab(h) {
            if (h === undefined)
                return;

            if ((typeof(h.CPU) === 'undefined') || (typeof(h.MEMORY) === 'undefined') || (typeof(h.CONNECTIONS) === 'undefined'))
                return;

            E('cpu-current').innerHTML = h.CPU[h.CPU.length - 1] + ' %';
            E('cpu-avg').innerHTML = h.cpu_avg.toFixed(0) + '%';
            E('cpu-max').innerHTML = h.cpu_max + '%';

            E('mem-current').innerHTML = h.MEMORY[h.MEMORY.length - 1] + ' MB';
            E('mem-avg').innerHTML = h.mem_avg.toFixed(0) + ' MB';
            E('mem-max').innerHTML = h.mem_max + ' MB';

            E('con-current').innerHTML = h.CONNECTIONS[h.CONNECTIONS.length - 1];
            E('con-avg').innerHTML = h.con_avg.toFixed(0);
            E('con-max').innerHTML = h.con_max;
        }

        function eval_nknmon(response) {

            nknmon = {
                CPU: 0,
                MEMORY: 0,
                CONNECTIONS: 0
            };

            try {
                eval(response);
            } catch (ex) {
                nknmon = {
                    CPU: 0,
                    MEMORY: 0,
                    CONNECTIONS: 0
                };
            }

            calc_nkn();
            nknChart.redraw();
        }

        function prepare_array(x) {
            var data = [],
                p = -450;
            for (var i = p; i <= 0; i++)
                data.push([x + i * 2000, 0]);
            return data;
        }

        function prepare_array_chart() {
            var x = (new Date()).getTime();
            x = parseInt(x / 1000) * 1000;
            return prepare_array(x);
        }

        function load_nknmon() {
            clearTimeout(idTimerPoll);
            $j.ajax({
                type: "get",
                url: "/update.cgi",
                data: {
                    output: "nknmon"
                },
                dataType: "script",
                cache: true,
                error: function(xhr) {
                    invoke_timer(2);
                },
                success: function(response) {
                    invoke_timer(2);
                    eval_nknmon(response);
                }
            });
        }

        function prepareData(data) {
            var newData = [];
            for (var i = 0; i < data.length; i++)
                newData.push(data[i]);
            return newData;
        }

        function switchPage(id) {
            if (id == "tab_nkn_node")
                location.href = "/nkn_node.asp";
            else if (id == "tab_nkn_info")
                location.href = "/nkn_info.asp";
            else if (id == "tab_nkn_logs")
                location.href = "/nkn_logs.asp";
            else if (id == "tab_nkn_wallet")
                location.href = "/nkn_wallet.asp";
            else if (id == "tab_nkn_neighbor")
                location.href = "/nkn_neighbor.asp";
            return false;
        }
    </script>
    <style>
        #tabs {
            margin-bottom: 0px;
        }
        
        .table-stat td {
            padding: 4px 8px;
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

        <div id="Loading" class="popup_bg"></div>

        <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

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
                                <h2 class="box_head round_top"><#menu8#> - <#NKN_MONITOR#></h2>
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
                                                <li class="active">
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

                                        <center>
                                            <table style="width: 100%; margin-top: 6px; margin-bottom: 6px;">
                                                <tr>
                                                    <td width="100%" align="center" style="text-align: center">
                                                        <div id="nkn_chart" style="width: 670px; padding-left: 5px;"></div>
                                                    </td>
                                                </tr>
                                            </table>
                                        </center>

                                        <table width="100%" align="center" cellpadding="4" cellspacing="0" class="table table-stat">
                                            <tr>
                                                <th width="9%" style="text-align: center">
                                                    <#Color#>
                                                </th>
                                                <th width="16%">
                                                    <#NAME#>
                                                </th>
                                                <th width="25%" style="text-align: right">
                                                    <#Current#>
                                                </th>
                                                <th width="25%" style="text-align: right">
                                                    <#Average#>
                                                </th>
                                                <th width="25%" style="text-align: right">
                                                    <#Maximum#>
                                                </th>
                                            </tr>
                                            <tr>
                                                <td width="9%" style="text-align:center; vertical-align: middle;">
                                                    <div id="cpu-sel" class="span12" style="border-radius: 5px;"></div>
                                                </td>
                                                <td width="16%">
                                                    <#NKN_CPU#>
                                                </td>
                                                <td width="25%" align="center" valign="top" style="text-align:right;font-weight: bold;"><span id="cpu-current"></span></td>
                                                <td width="25%" align="center" valign="top" style="text-align:right" id="cpu-avg"></td>
                                                <td width="25%" align="center" valign="top" style="text-align:right" id="cpu-max"></td>
                                            </tr>
                                            <tr>
                                                <td width="9%" style="text-align:center; vertical-align: middle;">
                                                    <div id="mem-sel" class="span12" style="border-radius: 5px;"></div>
                                                </td>
                                                <td width="16%">
                                                    <#NKN_MEMORY#>
                                                </td>
                                                <td width="25%" align="center" valign="top" style="text-align:right;font-weight: bold;"><span id="mem-current"></span></td>
                                                <td width="25%" align="center" valign="top" style="text-align:right" id="mem-avg"></td>
                                                <td width="25%" align="center" valign="top" style="text-align:right" id="mem-max"></td>
                                            </tr>
                                            <tr>
                                                <td width="9%" style="text-align:center; vertical-align: middle;">
                                                    <div id="con-sel" class="span12" style="border-radius: 5px;"></div>
                                                </td>
                                                <td width="16%">
                                                    <#NKN_CON#>
                                                </td>
                                                <td width="25%" align="center" valign="top" style="text-align:right;font-weight: bold;"><span id="con-current"></span></td>
                                                <td width="25%" align="center" valign="top" style="text-align:right" id='con-avg'></td>
                                                <td width="25%" align="center" valign="top" style="text-align:right" id='con-max'></td>
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