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

  ui.ListBox _foundRouter = new ui.ListBox();
  ui.VerticalPanel _mainPanel = new ui.VerticalPanel();
  ui.VerticalPanel _subPanel = new ui.VerticalPanel();

  ui.VerticalPanel _infoForSubPanel = new ui.VerticalPanel();
  ui.VerticalPanel _otherForSubPanel = new ui.VerticalPanel();

  async.StreamController _controllerSearchButton = new async.StreamController();

  async.Stream<int> get onClickSearchButton => _controllerSearchButton.stream;

  void clearFoundRouterList() {
    _foundRouter.clear();
  }

  void addFoundRouterList(String itemName) {
    _foundRouter.addItem(itemName);
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
      } else {
        _subPanel.clear();
        _subPanel.add(_otherForSubPanel);
      }
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
    _infoForSubPanel.add(new ui.Label("main operation"));
    _otherForSubPanel.add(new ui.Label("other operation"));
  }

}
