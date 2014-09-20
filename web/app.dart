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

void startSearchDevice() {
  mainView.clearFoundRouterList();
  if (deviceSearcher != null) {
    deviceSearcher.searchWanPPPDevice().then((int v){
      mainView.clearFoundRouterList();
      for(hetima.UPnpDeviceInfo info in deviceSearcher.deviceInfoList) {
        mainView.addFoundRouterList(info.getValue(hetima.UPnpDeviceInfo.KEY_USN, "*"));
      }
    });
  }
}

/*
ui.ListBox uiRouterListBox = new ui.ListBox();
ui.VerticalPanel vMainPanel = new ui.VerticalPanel();
ui.VerticalPanel vSubPanel = new ui.VerticalPanel();
ui.VerticalPanel infoPanel = new ui.VerticalPanel();
ui.VerticalPanel otherOperationPanel = new ui.VerticalPanel();
hetima.UpnpDeviceSearcher deviceSearcher = null;


void main() {
  initMainTab();
  initTab();

  vMainPanel.spacing = 10;

  ui.TabBar bar = new ui.TabBar();
  bar.addTabText("Info");
  bar.addTabText("mapped");
  bar.addTabText("baz");
  bar.selectTab(0);
  vMainPanel.add(bar);


  vMainPanel.add(vSubPanel);

  bar.addSelectionHandler(new event.SelectionHandlerAdapter((event.SelectionEvent evt) {
    int selectedTabIndx = evt.getSelectedItem();
    if (selectedTabIndx == 0) {
      vSubPanel.clear();
      vSubPanel.add(infoPanel);
    } else {
      vSubPanel.clear();
      vSubPanel.add(otherOperationPanel);
    }
  }));

  ui.RootPanel.get().add(vMainPanel);
  vSubPanel.clear();

  vSubPanel.add(infoPanel);

}

void updateInfo() {
  int l = deviceSearcher.deviceInfoList.length;
  int i = uiRouterListBox.getSelectedIndex();
  if (i < l) {
    hetima.UPnpDeviceInfo info = deviceSearcher.deviceInfoList[i];
    info.toString();
    infoPanel.clear();
    for (String d in info.toString().split("\r\n")) {
      ui.Html label = new ui.Html();
      label.text = d;
      infoPanel.add(label);
    }
  }
}

void updateMap() {
  int l = deviceSearcher.deviceInfoList.length;
  int i = uiRouterListBox.getSelectedIndex();
  if (i < l) {
    hetima.UPnpDeviceInfo info = deviceSearcher.deviceInfoList[i];
    otherOperationPanel.clear();
    hetima.UPnpPPPDevice pppDevice = new hetima.UPnpPPPDevice(info);
    pppDevice.requestGetGenericPortMapping(0).then((hetima.UPnpGetGenericPortMappingResponse response) {
      {
        ui.Html label = new ui.Html();
        label.text = response.toString();
        otherOperationPanel.add(label);
      }
    }).catchError((e){
      ;
    });
  }
}

void initTab() {
  {
    ui.Label label = new ui.Label();
    label.text = "main operation";
    infoPanel.add(label);
  }
  {
    ui.Label label = new ui.Label();
    label.text = "other operation";
    otherOperationPanel.add(label);
  }
}

void initMainTab() {
  ui.Button button = new ui.Button("search router", new event.ClickHandlerAdapter((event.ClickEvent event) {
    hetima.UpnpDeviceSearcher.createInstance(new hetimacl.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
      deviceSearcher = searcher;
      searcher.onReceive().listen((hetima.UPnpDeviceInfo info) {
        print("log:" + info.toString());
        bool isf = false;
        if (0 == uiRouterListBox.getItemCount()) {
          isf = true;
        }
        uiRouterListBox.clear();
        for (hetima.UPnpDeviceInfo i in searcher.deviceInfoList) {
          uiRouterListBox.addItem(i.getValue(hetima.UPnpDeviceInfo.KEY_LOCATION, "none"));
        }
        if (isf == true) {
          uiRouterListBox.setSelectedIndex(0);
          updateInfo();
          updateMap();
        }
      });
      searcher.searchWanPPPDevice();
    });
  }));
  vMainPanel.add(button);
  vMainPanel.add(uiRouterListBox);
  uiRouterListBox.addChangeHandler(new event.ChangeHandlerAdapter((event.ChangeEvent event) {
    updateInfo();
    updateMap();
  }));
}
 */
