public enum NetworkProtocol implements IndexingInterface {
    UDP (0, "UDP"),
    OSC (1, "OSC"),
    LSL (2, "LSL"),
    SERIAL (3, "Serial");

    private final int INDEX;
    private final String NAME;
    private static final NetworkProtocol[] VALUES = values();

    NetworkProtocol(int index, String name) {
        INDEX = index;
        NAME = name;
    }

    public int getIndex() {
        return INDEX;
    }

    public String getString() {
        return NAME;
    }

    public static NetworkProtocol getByIndex(int _index) {
        for (NetworkProtocol protocol : NetworkProtocol.values()) {
            if (protocol.getIndex() == _index) {
                return protocol;
            }
        }
        return null;
    }

    public static NetworkProtocol getByString(String _name) {
        for (NetworkProtocol protocol : NetworkProtocol.values()) {
            if (protocol.getString() == _name) {
                return protocol;
            }
        }
        return null;
    }

    public static List<String> getEnumStringsAsList() {
        List<String> enumStrings = new ArrayList<String>();
        for (IndexingInterface val : VALUES) {
            enumStrings.add(val.getString());
        }
        enumStrings.remove("Serial"); // #354
        return enumStrings;
    }
}

public enum NetworkDataType implements IndexingInterface {
    NONE (-1, "None", null, null),
    TIME_SERIES_FILTERED (0, "TimeSeriesFilt", "timeSeriesFiltered", "time-series-filtered"),
    TIME_SERIES_RAW (1, "TimeSeriesRaw", "timeSeriesRaw", "time-series-raw"),
    FOCUS (2, "Focus", "focus", "focus"),
    FFT (3, "FFT", "fft", "fft"),
    EMG (4, "EMG", "emg", "emg"),
    AVG_BAND_POWERS (5, "AvgBandPowers", "avgBandPowers", "avg-band-powers"),
    BAND_POWERS (6, "BandPowers", "bandPowers", "band-powers"),
    ACCEL_AUX (7, "AccelAux", "accelAux", "accel-aux"),
    PULSE (8, "Pulse", "pulse", "pulse"),
    EMG_JOYSTICK (9, "EMGJoystick", "emgJoystick", "emg-joystick"),
    MARKER (10, "Marker", "marker", "marker");

    private final int INDEX;
    private final String NAME;
    private final String UDP_KEY;
    private final String OSC_KEY;
    private static final NetworkDataType[] VALUES = values();

    NetworkDataType(int index, String name, String udpKey, String oscKey) {
        INDEX = index;
        NAME = name;
        UDP_KEY = udpKey;
        OSC_KEY = oscKey;
    }

    public int getIndex() {
        return INDEX;
    }

    public String getString() {
        return NAME;
    }

    public String getUDPKey() {
        return UDP_KEY;
    }

    public String getOSCKey() {
        return OSC_KEY;
    }

    public static NetworkDataType getByString(String _name) {
        for (NetworkDataType dataType : NetworkDataType.values()) {
            if (dataType.getString() == _name) {
                return dataType;
            }
        }
        return null;
    }
} 