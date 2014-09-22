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
  pppDevice.requestGetExternalIPAddress().then((String ip) {
    mainView.setGlobalIp(ip);
  }).catchError((e) {
    mainView.setGlobalIp("failed");
  });
  (new hetimacl.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> interfaceList) {
    mainView.clearNetworkInterface();
    for (hetima.HetiNetworkInterface i in interfaceList) {
      appview.AppNetworkInterface interface = new appview.AppNetworkInterface();
      interface.ip = i.address;
      interface.length = "${i.prefixLength}";
      mainView.addNetworkInterface(interface);
    }
  });
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
  requestPortMapInfo() {
    pppDevice.requestGetGenericPortMapping(newPortmappingIndex).then((hetima.UPnpGetGenericPortMappingResponse r) {
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

void startSearchPPPDevice() {
  if (deviceSearcher == null) {
    return;
  }
  mainView.clearFoundRouterList();

  deviceSearcher.searchWanPPPDevice().then((int v) {
    mainView.clearFoundRouterList();
    for (hetima.UPnpDeviceInfo info in deviceSearcher.deviceInfoList) {
      mainView.addFoundRouterList(info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*"));
    }
  });
}

void startAddPortMapp(appview.AppPortMapInfo i) {
  hetima.UPnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return null;
  }
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);

  pppDevice.requestAddPortMapping(int.parse(i.publicPort), i.protocol, int.parse(i.localPort), i.localIp, 1, i.description, 0).then((int v) {
    String result = "OK";
    if (v != 200) {
      result = " $result resultCode = ${v}";
    }
    ui.DialogBox dialogBox = appview.createDialogBox("#### Port Map ####", new ui.Html(result));
    dialogBox.show();
    dialogBox.center();
  }).catchError((e) {
    ui.DialogBox dialogBox = appview.createDialogBox("#### ERROR ####", new ui.Html("failed add port mapping"));
    dialogBox.show();
    dialogBox.center();
  });
}

void startDeletePortMapp(appview.AppPortMapInfo i) {
  hetima.UPnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return;
  }
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);

  pppDevice.requestDeletePortMapping(int.parse(i.publicPort), i.protocol).then((int v) {
    String result = "OK";
    if (v != 200) {
      result = " $result resultCode = ${v}";
    }
    ui.DialogBox dialogBox = appview.createDialogBox("#### Port Map ####", new ui.Html(result));
    dialogBox.show();
    dialogBox.center();
  }).catchError((e) {
    ui.DialogBox dialogBox = appview.createDialogBox("#### ERROR ####", new ui.Html("failed add port mapping"));
    dialogBox.show();
    dialogBox.center();
  });
}
