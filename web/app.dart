import 'dart:html';

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/text.dart' as text;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;
import 'package:dart_web_toolkit/validation.dart' as validation;
import 'package:hetima/hetima.dart' as hetima;
import 'package:hetima/hetima_cl.dart' as hetimacl;
import './mainview.dart' as appview;


hetima.UpnpDeviceSearcher deviceSearcher = null;
appview.MainView mainView = new appview.MainView();

void main() {
  setupUI();
  setupUpnp();
}

void setupUI() {
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
  hetima.UpnpDeviceSearcher.createInstance(new hetimacl.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
    deviceSearcher = searcher;
    searcher.onReceive().listen((hetima.UPnpDeviceInfo info) {
      print("log:" + info.toString());
      mainView.addFoundRouterList(info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*"));
    });
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

  (new hetimacl.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> interfaceList) {
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
