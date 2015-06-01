function CreateCutterWindow(self, varargin)
% MClustCutter.CreateCutterWindow

% varargin
CreateAxesControls = true;
CreateHideShow = true;
process_varargin(varargin);

MCS = MClust.GetSettings();
MCD = MClust.GetData();

%--------------------------------
% constants to make everything identical

uicHeight = self.uicHeight;
uicWidth  = self.uicWidth;
uicWidth0 = self.uicWidth0;
uicWidth1 = self.uicWidth1;
XLocs = self.XLocs;
dY = self.dY;
YLocs = self.YLocs;

self.CC_figHandle = figure(...
    'Name', 'Cutting Control Window',...
    'NumberTitle', 'off', ...
    'Tag', 'ClusterCutWindow', ...
    'HandleVisibility', 'On', ...
    'Position', MCS.ClusterCutWindow_Pos, ...
    'CloseRequestFcn', @(src,event)close(self));

MCS.PlaceWindow(self.CC_figHandle); % ADR 2013-12-12

% ---- Axes
if CreateAxesControls
    
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(1) uicWidth0 + uicWidth uicHeight], ...
        'Style', 'text', 'String', {MCD.TTfn, 'Axes'});
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(2) uicWidth0 uicHeight], ...
        'Style', 'text', 'String', ' X: ');
    self.xAxisLB = ...
        uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth0 YLocs(2) uicWidth uicHeight],...
        'Style', 'popupmenu', 'Tag', 'xdim', 'String', self.getFeatureNames(), ...
        'Callback', @(src,event)RedrawAxes(self), 'Value', 1, ...
        'TooltipString', 'Select x dimension');
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(3) uicWidth0 uicHeight], ...
        'Style', 'text', 'String', ' Y: ');
    self.yAxisLB = ...
        uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth0 YLocs(3) uicWidth uicHeight],...
        'Style', 'popupmenu', 'Tag', 'ydim', 'String', self.getFeatureNames(), ...
        'Callback', @(src,event)RedrawAxes(self), 'Value', 2, ...
        'TooltipString', 'Select y dimension');
    
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(4) uicWidth0 uicHeight], ...
        'Style', 'pushbutton', 'Tag', 'PrevAxis', 'String', '<', ...
        'Callback', @(src,event)StepBackwards(self), ...
        'TooltipString', 'Step backwards');
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth0 YLocs(4) uicWidth-uicWidth0 uicHeight], ...
        'Style', 'text', 'String', 'Axis');
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth YLocs(4) uicWidth0 uicHeight], ...
        'Style', 'pushbutton', 'Tag', 'NextAxis', 'String', '>', ...
        'Callback', @(src,event)StepForwards(self), ...
        'TooltipString', 'Step forwards');
    
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(5) uicWidth+uicWidth0 uicHeight], ...
        'Style', 'pushbutton', 'String', 'Cycle y dimensions', ...
        'Value', 0, 'Callback', @(src,event)CycleYDimensions(self), ...
        'TooltipString','Continuously step through current x dimension vs. all y dimensions');
    uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(6) uicWidth+uicWidth0 uicHeight], ...
        'Style', 'pushbutton', 'String', 'View all dimensions', ...
        'Value', 0, 'Callback', @(src,event)CycleAllDimensions(self), ...
        'TooltipString','Continuously step through all dimension pairs');
    
end
% ----- Drawing

self.redrawAxesButton = ...
    uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(7) uicWidth+uicWidth0 uicHeight], ...
    'Style', 'checkbox','Value', 0, 'Tag', 'RedrawAxes', 'String', 'Redraw Axes', ...
    'Callback', @(src,event)RedrawAxes(self), ...
    'TooltipString', 'If checked, redraw axes with each update.  Uncheck and recheck to redraw axes now.');

uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(8)+uicHeight/2 uicWidth-uicWidth0 uicHeight/2], ...
    'Style', 'text', 'String', 'Marker');

self.axisMarkerSelect = ...
    uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [uicWidth+XLocs(1)-uicWidth0 YLocs(8) uicWidth0 uicHeight], ...
    'Style', 'popupmenu', 'Value', MCS.ClusterCutWindow_Marker, 'Tag', 'PlotMarker', ...
    'String', MCS.ClusterCutWindow_MarkerList, ...
    'Callback', @(src,event)ChangeMarkers(self), ...
    'TooltipString', 'Change all markers');
self.axisMarkerSize = ...
    uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [uicWidth+XLocs(1) YLocs(8) uicWidth0 uicHeight], ...
    'Style', 'popupmenu', 'Value', MCS.ClusterCutWindow_MarkerSize, 'Tag', 'PlotMarkerSize', ...
    'String', MCS.ClusterCutWindow_MarkerSizeList, ...
    'Callback', @(src,event)ChangeMarkerSizes(self), ...
    'TooltipString', 'Change all marker sizes');

% ----- Clusters

%-----------------------------------
self.clusterPanel = ...
    uipanel('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(2) 0 0.95-XLocs(2) 1]);
self.uiScrollbar = ...
    uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [0.95 0 0.05 1], ...
    'Style', 'slider', 'Callback', @(src,event)RedrawClusters(self), ...
    'Value', 0, 'Min', -(MClustData.maxClusters-1), 'Max', 0, ...
    'SliderStep', [1/(MClustData.maxClusters-1) 10/(MClustData.maxClusters-1)], ...
    'TooltipString', 'Scroll clusters');

self.RedrawClusters();

%
if CreateHideShow
	uicontrol('Parent', self.CC_figHandle, ...
		'Units', 'Normalized', 'Position', [XLocs(1) YLocs(11) (uicWidth+uicWidth0)/2 uicHeight], ...
		'Style', 'pushbutton', 'String', 'Hide',  ...
		'Callback', @(src,event)HideClusters(self), ...
		'TooltipString', 'Hide all clusters');
	uicontrol('Parent', self.CC_figHandle, ...
		'Units', 'Normalized', 'Position', [XLocs(1)+(uicWidth+uicWidth0)/2 YLocs(11) (uicWidth+uicWidth0)/2 uicHeight], ...
		'Style', 'pushbutton', 'String', 'Show',  ...
		'Callback', @(src,event)ShowClusters(self), ...
		'TooltipString', 'Show all clusters');
end
% undo/redo

% % Cutter options
string = self.FindCutterFunctions();
if ~isempty(string)
    self.cutterFuncMenu = ...
        uicontrol('Parent', self.CC_figHandle, ...
        'Units', 'Normalized', 'Position', [0 YLocs(13) XLocs(2) uicHeight],...
        'Style', 'popupmenu',...
        'Value', 1, 'String', string, ...
        'Callback', @(src,event)CallCutterFunction(self));
end

% Load/Save/Clear clusters

% Exit (w, w/o export)

self.append = MClustUtils.TwoRadioSwitch('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [0 YLocs(16) XLocs(2) uicHeight], ...
    'AName', 'append', 'BName', 'overwrite');
self.append.SetB();

uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(17) uicWidth+uicWidth0 uicHeight], ...
    'Style', 'pushbutton', 'String','Export Clusters', ...
    'Callback', @(src,event)exportClusters(self), ...
    'TooltipString', 'Export and return to main window');

uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(18) uicWidth+uicWidth0 uicHeight], ...
    'Style', 'pushbutton', 'String','Exit (no export)', ...
    'Callback', @(src,event)ExitCutter(self, false), ...
    'TooltipString', 'Export and return to main window');

uicontrol('Parent', self.CC_figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(19) uicWidth+uicWidth0 uicHeight], ...
    'Style', 'pushbutton', 'String', 'Exit (export)',  ...
    'Callback', @(src,event)ExitCutter(self, true), ...
    'TooltipString', 'Export and return to main window');


end