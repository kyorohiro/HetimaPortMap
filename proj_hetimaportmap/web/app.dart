import 'dart:html';

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/text.dart' as text;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;
import 'package:dart_web_toolkit/validation.dart' as validation;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;
import 'package:hetimanet/hetimanet_chrome.dart' as hetima;

import 'package:hetimanet/src/net/hetisocket.dart' as hs;
import 'package:hetimanet/src/net/hetisocket_chrome.dart' as hetimanet_ch;
import 'package:hetimanet/src/http/hetihttp.dart' as hhttp;
import './mainview.dart' as appview;
import 'dart:convert' as convert;

/*
void main() {
  print("###start");
  hetimanet_ch.HetiSocketBuilderChrome bm = new hetimanet_ch.HetiSocketBuilderChrome();
  hhttp.HetiHttpClient c = new hhttp.HetiHttpClient(new hetimanet_ch.HetiSocketBuilderChrome());
  c.connect("www.google.com", 80).then((int v){
    print("###message${v}");
    _showDialog("title","message${v}");

    Map<String, String> t = {};
    t["Connection"] = "keep-alive";
    c.get("/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=android", t).then((hhttp.HetiHttpClientResponse res) {
      for (hhttp.HetiHttpResponseHeaderField f in res.message.headerField) {
        print(f.fieldName + ":" + f.fieldValue);
      }
      res.body.getByteFuture(0, res.message.index).then((List<int> v) {
        print("\r\n####header##\r\n" + convert.UTF8.decode(v) + "\r\n####\r\n");
        int len = res.getContentLength();
        print("--##AA00-");
        if (len != -1) {
          print("--##AA01-");
          res.body.getByteFuture(0, len).then((List<int> v) {
            print("--##AA01 AA-");
          });
        } else {
          print("--##AA02-");
          res.body.onFin().then((e) {
            res.body.getLength().then((int size) {
              c.close();
              print("--##AA02 BB-" + size.toString());
              res.body.getByteFuture(0, size).then((List<int> v) {
                print("--##AA03 BB-" + convert.UTF8.decode(v));
              });
            });
          });
        }
      });
    });
  }).catchError((e){
    print("###err");
    //_showDialog("title","err");
  });
//  hetimanet_ch.
//  hetimanet.HetiSocketBuilderChrome s;
//  hetima.HetiUdpSocket s;
      
//  setupUI();
//  setupUpnp();
}

void _showDialog(String title, String message) {
  ui.DialogBox dialogBox = appview.createDialogBox(title, new ui.Html(message));
  dialogBox.show();
  dialogBox.center();
}
*/
hetima.UpnpDeviceSearcher deviceSearcher = null;
appview.MainView mainView = new appview.MainView();

void main() {
  setupUI();
  setupUpnp();
}

void setupUI() {
  print("### st setupUI");
  mainView.intialize();
  mainView.onClickSearchButton.listen((int v) {
    print("### search router");
    startSearchPPPDevice();
  });
  mainView.onSelectTab.listen((int v) {
    print("### select tag ${v}");
    if (v == appview.MainView.MAIN) {
    } else if (v == appview.MainView.LIST) {
      startUpdatePortMappedList();
    } else if (v == appview.MainView.INFO) {
      startUpdateIpInfo();
    } else {
    }
  });

  mainView.onSelectRouter.listen((String v) {
    print("### select router ${v}");
  });

  mainView.onClieckAddPortMapButton.listen((appview.AppPortMapInfo i) {
    print("### add port map ${i.description}");
    startAddPortMapp(i);
  });

  mainView.onClieckDelPortMapButton.listen((appview.AppPortMapInfo i) {
    print("### del port map ${i.description}");
    startDeletePortMapp(i);
  });
}

void setupUpnp() {
  print("### st setupUpnp");
  hetima.UpnpDeviceSearcher.createInstance(new hetima.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
    print("### ok setupUpnp ${searcher}");
    deviceSearcher = searcher;
    searcher.onReceive().listen((hetima.UPnpDeviceInfo info) {
      print("###log:" + info.toString());
      mainView.addFoundRouterList(info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*"));
    });
  }).catchError((e){
    print("### er setupUpnp ${e}");
  });
}

hetima.UPnpDeviceInfo getCurrentRouter() {
  if (deviceSearcher.deviceInfoList.length <= 0) {
    return null;
  }
  String routerName = mainView.currentSelectRouter();
  for (hetima.UPnpDeviceInfo info in deviceSearcher.deviceInfoList) {
    if (info == null) {
      continue;
    }
    if (routerName == info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*")) {
      return info;
    }
  }
  return deviceSearcher.deviceInfoList.first;
}

void startUpdateIpInfo() {
  if (deviceSearcher == null) {
    return;
  }

  hetima.UPnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return;
  }

  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
  pppDevice.requestGetExternalIPAddress().then((hetima.UPnpGetExternalIPAddressResponse ip) {
    if (ip.resultCode == -405) {
      //retry at mpost request
      return pppDevice.requestGetExternalIPAddress(hetima.UPnpPPPDevice.MODE_M_POST).then((hetima.UPnpGetExternalIPAddressResponse ip) {
        mainView.setGlobalIp(ip.externalIp);
      });
    } else {
      mainView.setGlobalIp(ip.externalIp);
    }
  }).catchError((e) {
    mainView.setGlobalIp("failed");
  });

  (new hetima.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> interfaceList) {
    mainView.clearNetworkInterface();
    for (hetima.HetiNetworkInterface i in interfaceList) {
      appview.AppNetworkInterface interface = new appview.AppNetworkInterface();
      interface.ip = i.address;
      interface.length = "${i.prefixLength}";
      interface.name = "${i.name}";
      mainView.addNetworkInterface(interface);
    }
  });

  mainView.setRouterAddress(info.presentationURL);
}

void startUpdatePortMappedList() {
  mainView.clearPortMappInfo();
  if (deviceSearcher == null) {
    return;
  }
  hetima.UPnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return;
  }
  List<hetima.UPnpDeviceInfo> deviceInfoList = deviceSearcher.deviceInfoList;
  int newPortmappingIndex = 0;
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
  int mode = hetima.UPnpPPPDevice.MODE_POST;
  requestPortMapInfo() {
    pppDevice.requestGetGenericPortMapping(newPortmappingIndex, mode).then((hetima.UPnpGetGenericPortMappingResponse r) {
      if (r.resultCode == -405 && mode == hetima.UPnpPPPDevice.MODE_POST) {
        mode = hetima.UPnpPPPDevice.MODE_M_POST;
        requestPortMapInfo();
        return;
      }

      if (r.resultCode != 200) {
        return;
      }

      appview.AppPortMapInfo portMapInfo = new appview.AppPortMapInfo();
      portMapInfo.publicPort = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
      portMapInfo.localIp = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
      portMapInfo.localPort = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewInternalPort, "");
      portMapInfo.protocol = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewProtocol, "");
      portMapInfo.description = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
      if (portMapInfo.localPort.replaceAll(" |\t|\r|\n", "") == "" && portMapInfo.localIp.replaceAll(" |\t|\r|\n", "") == "") {
        return;
      }
      mainView.addPortMappInfo(portMapInfo);
      newPortmappingIndex++;
      requestPortMapInfo();
    }).catchError((e) {
    });
  }
  requestPortMapInfo();
}

bool isSearching = false;
void startSearchPPPDevice() {
  if (deviceSearcher == null || isSearching) {
    print("### search router:null");
    _showDialog("#### Search Router ####", "Not Found Router");
    return;
  }
  mainView.clearFoundRouterList();

  deviceSearcher.searchWanPPPDevice().then((int v) {
    isSearching  = false;
    mainView.clearFoundRouterList();
    if (deviceSearcher.deviceInfoList == null || deviceSearcher.deviceInfoList.length <= 0) {
      _showDialog("#### Search Router ####", "Not Found Router");
      return;
    }
    for (hetima.UPnpDeviceInfo info in deviceSearcher.deviceInfoList) {
      mainView.addFoundRouterList(info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*"));
    }
  }).catchError((e){
    isSearching  = false;
  });
}

void _showDialog(String title, String message) {
  ui.DialogBox dialogBox = appview.createDialogBox(title, new ui.Html(message));
  dialogBox.show();
  dialogBox.center();
}

void startAddPortMapp(appview.AppPortMapInfo i) {
  hetima.UPnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return null;
  }
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);

  showDialogAPM(hetima.UPnpAddPortMappingResponse resp) {
    String result = "OK";
    if (resp.resultCode != 200) {
      result = " $result resultCode = ${resp.resultCode}";
    }
    _showDialog("#### Port Map ####", result);
  }
  ;
  pppDevice.requestAddPortMapping(int.parse(i.publicPort), i.protocol, int.parse(i.localPort), i.localIp, 1, i.description, 0).then((hetima.UPnpAddPortMappingResponse resp) {
    if (resp.resultCode == -405) {
      return pppDevice.requestAddPortMapping(int.parse(i.publicPort), i.protocol, int.parse(i.localPort), i.localIp, 1, i.description, 0, hetima.UPnpPPPDevice.MODE_M_POST).then((hetima.UPnpAddPortMappingResponse resp) {
        showDialogAPM(resp);
      });
    } else {
      showDialogAPM(resp);
    }
  }).catchError((e) {
    _showDialog("#### ERROR ####", "failed add port mapping");
  });
}

void startDeletePortMapp(appview.AppPortMapInfo i) {
  hetima.UPnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return;
  }
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);

  showDialogDPM(hetima.UPnpDeletePortMappingResponse resp) {
    if (resp.resultCode != 200) {
      _showDialog("#### Delete Port Map NG ####", "resultCode = ${resp.resultCode}");
    } else {
      //_showDialog("#### Delete Port Map OK ####", "OK");      
    }
  }
  ;
  pppDevice.requestDeletePortMapping(int.parse(i.publicPort), i.protocol).then((hetima.UPnpDeletePortMappingResponse resp) {
    if (resp.resultCode == -405) {
      return pppDevice.requestDeletePortMapping(int.parse(i.publicPort), i.protocol, hetima.UPnpPPPDevice.MODE_M_POST).then((hetima.UPnpDeletePortMappingResponse resp) {
        showDialogDPM(resp);
      });
    } else {
      showDialogDPM(resp);
    }
  }).catchError((e) {
    _showDialog("#### ERROR ####", "failed delete port mapping");
  });
}
