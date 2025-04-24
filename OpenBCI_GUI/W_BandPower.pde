
////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//    W_BandPowers.pde                                                                                //
//                                                                                                    //
//    This is a band power visualization widget!                                                      //
//    (Couldn't think up more)                                                                        //
//    This is for visualizing the power of each brainwave band: delta, theta, alpha, beta, gamma      //
//    Averaged over all channels                                                                      //
//                                                                                                    //
//    Created by: Wangshu Sun, May 2017                                                               //
//    Modified by: Richard Waltman, March 2022                                                        //
//    Refactored by: Richard Waltman, March 2025                                                      //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////

class W_BandPower extends WidgetWithSettings {
    // indexes
    private final int DELTA = 0; // 1-4 Hz
    private final int THETA = 1; // 4-8 Hz
    private final int ALPHA = 2; // 8-13 Hz
    private final int BETA = 3; // 13-30 Hz
    private final int GAMMA = 4; // 30-55 Hz
    
    private final int NUM_BANDS = 5;
    private float[] activePower = new float[NUM_BANDS];
    private float[] normalizedBandPowers = new float[NUM_BANDS];

    private GPlot bp_plot;
    public ExGChannelSelect bpChanSelect;
    private boolean prevChanSelectIsVisible = false;

    private List<controlP5.Controller> cp5ElementsToCheck;

    int[] autoCleanTimers;
    boolean[] previousThresholdCrossed;

    W_BandPower() {
        super();
        widgetTitle = "Band Power";

        autoCleanTimers = new int[currentBoard.getNumEXGChannels()];
        previousThresholdCrossed = new boolean[currentBoard.getNumEXGChannels()];

        // Setup for the BandPower plot
        bp_plot = new GPlot(ourApplet, x, y-NAV_HEIGHT, w, h+NAV_HEIGHT);
        // bp_plot.setPos(x, y+NAV_HEIGHT);
        bp_plot.setDim(w, h);
        bp_plot.setLogScale("y");
        bp_plot.setYLim(0.1, 100);
        bp_plot.setXLim(0, 5);
        bp_plot.getYAxis().setNTicks(9);
        bp_plot.getXAxis().setNTicks(0);
        bp_plot.getTitle().setTextAlignment(LEFT);
        bp_plot.getTitle().setRelativePos(0);
        bp_plot.setAllFontProperties("Arial", 0, 14);
        bp_plot.getYAxis().getAxisLabel().setText("Power — (uV)^2 / Hz");
        bp_plot.getXAxis().setAxisLabelText("EEG Power Bands");
        bp_plot.getXAxis().getAxisLabel().setOffset(42f);
        bp_plot.startHistograms(GPlot.VERTICAL);
        bp_plot.getHistogram().setDrawLabels(true);
        bp_plot.getXAxis().setFontColor(OPENBCI_DARKBLUE);
        bp_plot.getXAxis().setLineColor(OPENBCI_DARKBLUE);
        bp_plot.getXAxis().getAxisLabel().setFontColor(OPENBCI_DARKBLUE);
        bp_plot.getYAxis().setFontColor(OPENBCI_DARKBLUE);
        bp_plot.getYAxis().setLineColor(OPENBCI_DARKBLUE);
        bp_plot.getYAxis().getAxisLabel().setFontColor(OPENBCI_DARKBLUE);

        //setting border of histograms to match BG
        bp_plot.getHistogram().setLineColors(new color[]{
            color(245), color(245), color(245), color(245), color(245)
          }
        );
        //setting bg colors of histogram bars to match the color scheme of the channel colors w/ an opacity of 150/255
        bp_plot.getHistogram().setBgColors(new color[] {
                color((int)channelColors[6], 200),
                color((int)channelColors[4], 200),
                color((int)channelColors[3], 200),
                color((int)channelColors[2], 200), 
                color((int)channelColors[1], 200),
            }
        );
        //setting color of text label for each histogram bar on the x axis
        bp_plot.getHistogram().setFontColor(OPENBCI_DARKBLUE);
    }

    @Override
    protected void initWidgetSettings() {
        super.initWidgetSettings();
        widgetSettings.set(BPAutoClean.class, BPAutoClean.OFF)
                    .set(BPAutoCleanThreshold.class, BPAutoCleanThreshold.FIFTY)
                    .set(BPAutoCleanTimer.class, BPAutoCleanTimer.THREE_SECONDS)
                    .set(FFTSmoothingFactor.class, globalFFTSettings.getSmoothingFactor())
                    .set(FFTFilteredEnum.class, globalFFTSettings.getFilteredEnum());

        initDropdown(BPAutoClean.class, "bandPowerAutoCleanDropdown", "Auto Clean");
        initDropdown(BPAutoCleanThreshold.class, "bandPowerAutoCleanThresholdDropdown", "Threshold");
        initDropdown(BPAutoCleanTimer.class, "bandPowerAutoCleanTimerDropdown", "Timer");
        initDropdown(FFTSmoothingFactor.class, "bandPowerSmoothingDropdown", "Smooth");
        initDropdown(FFTFilteredEnum.class, "bandPowerDataFilteringDropdown", "Filtered?");

        bpChanSelect = new ExGChannelSelect(ourApplet, x, y, w, navH);
        bpChanSelect.activateAllButtons();
        cp5ElementsToCheck = new ArrayList<controlP5.Controller>();
        cp5ElementsToCheck.addAll(bpChanSelect.getCp5ElementsForOverlapCheck());
        saveActiveChannels(bpChanSelect.getActiveChannels());
        widgetSettings.saveDefaults();
    }

    @Override
    protected void applySettings() {
        updateDropdownLabel(BPAutoClean.class, "bandPowerAutoCleanDropdown");
        updateDropdownLabel(BPAutoCleanThreshold.class, "bandPowerAutoCleanThresholdDropdown");
        updateDropdownLabel(BPAutoCleanTimer.class, "bandPowerAutoCleanTimerDropdown");
        updateDropdownLabel(FFTSmoothingFactor.class, "bandPowerSmoothingDropdown");
        updateDropdownLabel(FFTFilteredEnum.class, "bandPowerDataFilteringDropdown");
        applyActiveChannels(bpChanSelect);
    }

    @Override
    protected void updateChannelSettings() {
        if (bpChanSelect != null) {
            saveActiveChannels(bpChanSelect.getActiveChannels());
        }
    }

    public void update() {
        super.update();

        // If enabled, automatically turn channels on or off in ExGChannelSelect for this widget
        autoCleanByEnableDisableChannels();
        
        //Update channel checkboxes and active channels
        bpChanSelect.update(x, y, w);
        
        //Flex the Gplot graph when channel select dropdown is open/closed
        if (bpChanSelect.isVisible() != prevChanSelectIsVisible) {
            flexGPlotSizeAndPosition();
            prevChanSelectIsVisible = bpChanSelect.isVisible();
        }

        GPointsArray bp_points = new GPointsArray(dataProcessing.headWidePower.length);
        bp_points.add(DELTA + 0.5, activePower[DELTA], "DELTA\n0.5-4Hz");
        bp_points.add(THETA + 0.5, activePower[THETA], "THETA\n4-8Hz");
        bp_points.add(ALPHA + 0.5, activePower[ALPHA], "ALPHA\n8-13Hz");
        bp_points.add(BETA + 0.5, activePower[BETA], "BETA\n13-32Hz");
        bp_points.add(GAMMA + 0.5, activePower[GAMMA], "GAMMA\n32-100Hz");
        bp_plot.setPoints(bp_points);

        if (bpChanSelect.isVisible()) {
            lockElementsOnOverlapCheck(cp5ElementsToCheck);
        }
    }

    public void draw() {
        super.draw();
        pushStyle();

        //remember to refer to x,y,w,h which are the positioning variables of the Widget class
        // Draw the third plot
        bp_plot.beginDraw();
        bp_plot.drawBackground();
        bp_plot.drawBox();
        bp_plot.drawXAxis();
        bp_plot.drawYAxis();
        bp_plot.drawGridLines(GPlot.HORIZONTAL);
        bp_plot.drawHistograms();
        bp_plot.endDraw();

        //for this widget need to redraw the grey bar, bc the FFT plot covers it up...
        fill(200, 200, 200);
        rect(x, y - NAV_HEIGHT, w, NAV_HEIGHT); //button bar

        popStyle();
        bpChanSelect.draw();
    }

    public void screenResized() {
        super.screenResized();

        flexGPlotSizeAndPosition();

        bpChanSelect.screenResized(ourApplet);
    }

    public void mousePressed() {
        super.mousePressed();
        bpChanSelect.mousePressed(this.dropdownIsActive); //Calls channel select mousePressed and checks if clicked
    }

    void flexGPlotSizeAndPosition() {
        if (bpChanSelect.isVisible()) {
            bp_plot.setPos(x, y + bpChanSelect.getHeight() - navH);
            bp_plot.setOuterDim(w, h - bpChanSelect.getHeight() + navH);
        } else {
            bp_plot.setPos(x, y - navH);
            bp_plot.setOuterDim(w, h + navH);
        }
    }

    public float[] getNormalizedBPSelectedChannels() {
        return normalizedBandPowers;
    }

    private void autoCleanByEnableDisableChannels() {
        BPAutoClean autoClean = widgetSettings.get(BPAutoClean.class);
        BPAutoCleanThreshold autoCleanThreshold = widgetSettings.get(BPAutoCleanThreshold.class);
        BPAutoCleanTimer autoCleanTimer = widgetSettings.get(BPAutoCleanTimer.class);
        if (autoClean == BPAutoClean.OFF) {
            return;
        }

        int numChannels = currentBoard.getNumEXGChannels();
        for (int i = 0; i < numChannels; i++) {
            float uvrms = dataProcessing.data_std_uV[i];
            boolean thresholdCrossed = uvrms > autoCleanThreshold.getValue();

            int currentMillis = millis();

            //Check for state change. Reset timer on either state.
            if (thresholdCrossed != previousThresholdCrossed[i]) {
                previousThresholdCrossed[i] = thresholdCrossed;
                autoCleanTimers[i] = currentMillis;
            }
            
            //Auto-disable a channel if it's above the threshold and has been for the timer duration
            boolean timerDurationExceeded = currentMillis - autoCleanTimers[i] > autoCleanTimer.getValue();
            if (timerDurationExceeded) {
                boolean enableChannel = !thresholdCrossed;
                bpChanSelect.setToggleState(i, enableChannel);
            } 
        }
    }

    public void setAutoClean(int n) {
        widgetSettings.setByIndex(BPAutoClean.class, n);
        Arrays.fill(previousThresholdCrossed, false);
        Arrays.fill(autoCleanTimers, 0);
    }

    public void setAutoCleanThreshold(int n) {
        widgetSettings.setByIndex(BPAutoCleanThreshold.class, n);
    }

    public void setAutoCleanTimer(int n) {
        widgetSettings.setByIndex(BPAutoCleanTimer.class, n);
    }

    //Called in DataProcessing.pde to update data even if widget is closed
    public void updateBandPowerWidgetData() {
        float normalizingSum = 0;

        for (int i = 0; i < NUM_BANDS; i++) {
            float sum = 0;
            for (int j = 0; j < bpChanSelect.getActiveChannels().size(); j++) {
                int chan = bpChanSelect.getActiveChannels().get(j);
                sum += dataProcessing.avgPowerInBins[chan][i];
            }
            activePower[i] = sum / bpChanSelect.getActiveChannels().size();
            normalizingSum += activePower[i];
        }

        for (int i = 0; i < NUM_BANDS; i++) {
            normalizedBandPowers[i] = activePower[i] / normalizingSum;
        }
    }

    public void setSmoothingDropdownFrontend(FFTSmoothingFactor _smoothingFactor) {
        widgetSettings.set(FFTSmoothingFactor.class, _smoothingFactor);
        updateDropdownLabel(FFTSmoothingFactor.class, "bandPowerSmoothingDropdown");
    }

    public void setFilteringDropdownFrontend(FFTFilteredEnum _filteredEnum) {
        widgetSettings.set(FFTFilteredEnum.class, _filteredEnum);
        updateDropdownLabel(FFTFilteredEnum.class, "bandPowerDataFilteringDropdown");
    }
};

public void bandPowerAutoCleanDropdown(int n) {
    ((W_BandPower) widgetManager.getWidget("W_BandPower")).setAutoClean(n);
}

public void bandPowerAutoCleanThresholdDropdown(int n) {
    ((W_BandPower) widgetManager.getWidget("W_BandPower")).setAutoCleanThreshold(n);
}

public void bandPowerAutoCleanTimerDropdown(int n) {
    ((W_BandPower) widgetManager.getWidget("W_BandPower")).setAutoCleanTimer(n);
}

public void bandPowerSmoothingDropdown(int n) {
    globalFFTSettings.setSmoothingFactor(FFTSmoothingFactor.values()[n]);
    FFTSmoothingFactor smoothingFactor = globalFFTSettings.getSmoothingFactor();
    ((W_BandPower) widgetManager.getWidget("W_BandPower")).setSmoothingDropdownFrontend(smoothingFactor);
    ((W_Fft) widgetManager.getWidget("W_Fft")).setSmoothingDropdownFrontend(smoothingFactor);
}

public void bandPowerDataFilteringDropdown(int n) {
    globalFFTSettings.setFilteredEnum(FFTFilteredEnum.values()[n]);
    FFTFilteredEnum filteredEnum = globalFFTSettings.getFilteredEnum();
    ((W_BandPower) widgetManager.getWidget("W_BandPower")).setFilteringDropdownFrontend(filteredEnum);
    ((W_Fft) widgetManager.getWidget("W_Fft")).setFilteringDropdownFrontend(filteredEnum);
}