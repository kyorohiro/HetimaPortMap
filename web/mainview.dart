import 'dart:html';

import 'package:chrome/chrome_app.dart' as chrome;
import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/text.dart' as text;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;
import 'package:dart_web_toolkit/validation.dart' as validation;
import './mainview.dart' as appview;
import 'dart:async' as async;

class MainView {

  static const int MAIN = 0;
  static const int LIST = 1;

  ui.ListBox _foundRouter = new ui.ListBox();
  ui.VerticalPanel _mainPanel = new ui.VerticalPanel();
  ui.VerticalPanel _subPanel = new ui.VerticalPanel();

  ui.VerticalPanel _infoForSubPanel = new ui.VerticalPanel();
  ui.VerticalPanel _otherForSubPanel = new ui.VerticalPanel();

  async.StreamController _controllerSearchButton = new async.StreamController.broadcast();
  async.StreamController _controllerTab = new async.StreamController.broadcast();
  async.StreamController _controllerSelectRouter = new async.StreamController.broadcast();

  async.Stream<int> get onClickSearchButton => _controllerSearchButton.stream;
  async.Stream<int> get onSelectTab => _controllerTab.stream;
  async.Stream<String> get onSelectRouter => _controllerSelectRouter.stream;

  void clearFoundRouterList() {
    _foundRouter.clear();
  }

  void addFoundRouterList(String itemName) {
    _foundRouter.addItem(itemName);
  }

  List<AppPortMapInfo> portMapList = [];
  void clearPortMappInfo() {
    portMapList.clear();
  }
  void addPortMappInfo(AppPortMapInfo info) {
    portMapList.add(info);
    updateRouterList();
  }
  String currentSelectRouter() {
    if(_foundRouter.getSelectedIndex() == -1) {
      return "";
    }
    return _foundRouter.getValue(_foundRouter.getSelectedIndex());
  }
  void intialize() {
    initButton();
    initMainTab();

    _mainPanel.spacing = 10;

    ui.TabBar bar = new ui.TabBar();
    bar.addTabText("main");
    bar.addTabText("list");
    bar.selectTab(0);
    _mainPanel.add(bar);
    _mainPanel.add(_subPanel);

    bar.addSelectionHandler(new event.SelectionHandlerAdapter((event.SelectionEvent evt) {
      int selectedTabIndx = evt.getSelectedItem();
      if (selectedTabIndx == 0) {
        _subPanel.clear();
        _subPanel.add(_infoForSubPanel);
        _controllerTab.add(MAIN);
      } else {
        _subPanel.clear();
        _subPanel.add(_otherForSubPanel);
        _controllerTab.add(LIST);
      }
    }));

    _foundRouter.addChangeHandler(new event.ChangeHandlerAdapter((event.ChangeEvent event) {
      _controllerSelectRouter.add(_foundRouter.getValue(_foundRouter.getSelectedIndex()));
    }));

    ui.RootPanel.get().add(_mainPanel);
    _subPanel.clear();

    _subPanel.add(_infoForSubPanel);

  }

  void initButton() {
    ui.Button button = new ui.Button("search router", new event.ClickHandlerAdapter((event.ClickEvent event) {
      _controllerSearchButton.add(0);
    }));
    _mainPanel.add(button);
  }

  void initMainTab() {
    _mainPanel.add(_foundRouter);
    _foundRouter.addChangeHandler(new event.ChangeHandlerAdapter((event.ChangeEvent event) {
    }));
    {
      _infoForSubPanel.add(new ui.Label("main operation"));
    }
    {
      _otherForSubPanel.add(new ui.Label("other operation"));
      updateRouterList();
    }
  }

  void updateRouterList() {
    //
    // clear
    _otherForSubPanel.clear();

    //
    // Create a grid
    ui.Grid grid = new ui.Grid(1+portMapList.length, 5);
    grid.addStyleName("cw-FlexTable");
     
    // Add images to the grid
    int numRows = grid.getRowCount();
    int numColumns = grid.getColumnCount();
    {
      grid.setWidget(0, 0, new ui.Html("Description"));
      grid.setWidget(0, 1, new ui.Html("Protocol"));
      grid.setWidget(0, 2, new ui.Html("Public Port"));
      grid.setWidget(0, 3, new ui.Html("Local IP"));
      grid.setWidget(0, 4, new ui.Html("Local Port"));        
    }

    int row = 1;
    for (AppPortMapInfo i in portMapList) {
      ui.Html l0 = new ui.Html("${i.description}");
      ui.Html l1 = new ui.Html("${i.protocol}");
      ui.Html l2 = new ui.Html("${i.publicPort}");
      ui.Html l3 = new ui.Html("${i.localIp}");
      ui.Html l4 = new ui.Html("${i.localPort}");
      l0.addStyleName("hetima-grid");
      l1.addStyleName("hetima-grid");
      l2.addStyleName("hetima-grid");
      l3.addStyleName("hetima-grid");
      l4.addStyleName("hetima-grid");

      grid.setWidget(row, 0, l0);
      grid.setWidget(row, 1, l1);
      grid.setWidget(row, 2, l2);
      grid.setWidget(row, 3, l3);
      grid.setWidget(row, 4, l4);  
      row++;
    }
    _otherForSubPanel.add(grid);
  }
}

class AppPortMapInfo
{
  String protocol = "";
  String publicPort = "";
  String localIp = "";
  String localPort = "";
  String description = "";
}
