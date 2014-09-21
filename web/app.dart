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
  mainView.intialize();
  mainView.onClickSearchButton.listen((int v) {
    print("###a");
    startSearchDevice();
  });
  mainView.onSelectTab.listen((int v) {
    if (v == appview.MainView.MAIN) {
      print("### main");
    } else if(v == appview.MainView.LIST){
      print("### list");
      startUpdateList();
    } else if(v == appview.MainView.INFO){
      print("### info");
      startUpdateIpInfo();
    } else {
      print("### other");
    }
  });
  mainView.onSelectRouter.listen((String v) {
    print("### r "+v);
  });
  
  mainView.onClieckAddPortMapButton.listen((appview.AppPortMapInfo i) {
    print("### p "+i.description); 
    startAddPortMapp(i);
  });
  setup();
}

void setup() {
  hetima.UpnpDeviceSearcher.createInstance(new hetimacl.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
    deviceSearcher = searcher;
    searcher.onReceive().listen((hetima.UPnpDeviceInfo info) {
      print("log:" + info.toString());
      mainView.addFoundRouterList(info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*"));
    });
  });
}

hetima.UPnpDeviceInfo getRouter() {
  if(deviceSearcher.deviceInfoList.length<=0) {
    return null;
  }
  String routerName = mainView.currentSelectRouter();
  for(hetima.UPnpDeviceInfo info in deviceSearcher.deviceInfoList) {
    if(routerName == info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*")) {
      return info;
    }
  }
  return deviceSearcher.deviceInfoList.first;
}

void startUpdateIpInfo() {
  if (deviceSearcher == null) {
    return;
  }

  hetima.UPnpDeviceInfo info = getRouter();
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
  pppDevice.requestGetExternalIPAddress().then((String ip){
    mainView.setGlobalIp(ip);
  }).catchError((e) {
    mainView.setGlobalIp("failed");
  });
  (new hetimacl.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> interfaceList) {
    mainView.clearNetworkInterface();
    for(hetima.HetiNetworkInterface i in interfaceList) {
      appview.AppNetworkInterface interface = new appview.AppNetworkInterface();
      interface.ip = i.address;
      interface.length = "${i.prefixLength}";
      mainView.addNetworkInterface(interface);
    }
//    i.first
  });
}

void startUpdateList() {
  mainView.clearPortMappInfo();
  if (deviceSearcher == null) {
    return;
  }
  hetima.UPnpDeviceInfo info = getRouter();
  List<hetima.UPnpDeviceInfo> deviceInfoList = deviceSearcher.deviceInfoList;
  int index = 0;
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
  a() {
    pppDevice.requestGetGenericPortMapping(index).then((hetima.UPnpGetGenericPortMappingResponse r) {
      if(r.resultCode != 200) {
        return;
      }

      appview.AppPortMapInfo portMapInfo = new appview.AppPortMapInfo();
      portMapInfo.publicPort = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
      portMapInfo.localIp = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
      portMapInfo.localPort = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewInternalPort, "");
      portMapInfo.protocol = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewProtocol, "");
      portMapInfo.description = r.getValue(hetima.UPnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
      if(portMapInfo.localPort.replaceAll(" |\t|\r|\n", "") == "" && portMapInfo.localIp.replaceAll(" |\t|\r|\n", "") == "")
      {
        return;
      }
       mainView.addPortMappInfo(portMapInfo);
      index++;
      a();
    }).catchError((e){
    });
  }
  a();
}
void startSearchDevice() {
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

void startAddPortMapp(appview.AppPortMapInfo i)
{
  hetima.UPnpDeviceInfo info = getRouter();
  hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);

  pppDevice.requestAddPortMapping(
      int.parse(i.publicPort), i.protocol, int.parse(i.localPort), i.localIp,
      1, i.description, 0).then((int v){
    String result = "OK";
    if(v != 200) {
      result = " $result resultCode = ${v}";
    }
    ui.DialogBox dialogBox = appview.createDialogBox("#### Port Map ####", new ui.Html(result));
    dialogBox.show();
    dialogBox.center();
  }).catchError((e){
    ui.DialogBox dialogBox = appview.createDialogBox("#### ERROR ####", new ui.Html("failed add port mapping"));
    dialogBox.show();
    dialogBox.center();
  });
}


