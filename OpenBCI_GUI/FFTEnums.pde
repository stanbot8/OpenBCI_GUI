
public class GlobalFFTSettings {
    public FFTSmoothingFactor smoothingFactor = FFTSmoothingFactor.SMOOTH_90;
    public FFTFilteredEnum dataIsFiltered = FFTFilteredEnum.FILTERED;

    GlobalFFTSettings() {
        // Constructor
    }

    public void setSmoothingFactor(FFTSmoothingFactor factor) {
        this.smoothingFactor = factor;
    }

    public FFTSmoothingFactor getSmoothingFactor() {
        return smoothingFactor;
    }

    public void setFilteredEnum(FFTFilteredEnum filteredEnum) {
        this.dataIsFiltered = filteredEnum;
    }

    public FFTFilteredEnum getFilteredEnum() {
        return dataIsFiltered;
    }

    public boolean getDataIsFiltered() {
        return dataIsFiltered == FFTFilteredEnum.FILTERED;
    }
}   


// Used by FFT Widget, Band Power Widget, and Head Plot Widget
public enum FFTSmoothingFactor implements IndexingInterface {
    NONE (0, 0.0f, "O.O"),
    SMOOTH_50 (1, 0.5f, "0.5"),
    SMOOTH_75 (2, 0.75f, "0.75"),
    SMOOTH_90 (3, 0.9f, "0.9"),
    SMOOTH_95 (4, 0.95f, "0.95"),
    SMOOTH_98 (5, 0.98f, "0.98"),
    SMOOTH_99 (6, 0.99f, "0.99"),
    SMOOTH_999 (7, 0.999f, "0.999");

    private final int index;
    private final float value;
    private final String label;
    private static final FFTSmoothingFactor[] values = values();

    FFTSmoothingFactor(int index, float value, String label) {
        this.index = index;
        this.value = value;
        this.label = label;
    }

    public float getValue() {
        return value;
    }

    @Override
    public String getString() {
        return label;
    }

    @Override
    public int getIndex() {
        return index;
    }

    public static List<String> getEnumStringsAsList() {
        List<String> enumStrings = new ArrayList<>();
        for (IndexingInterface enumValue : values) {
            enumStrings.add(enumValue.getString());
        }
        return enumStrings;
    }
}

// Used by FFT Widget and Band Power Widget
public enum FFTFilteredEnum implements IndexingInterface {
    FILTERED (0, "Filtered"),
    UNFILTERED (1, "Unfilt.");

    private final int index;
    private final String label;
    private static final FFTFilteredEnum[] values = values();

    FFTFilteredEnum(int index, String label) {
        this.index = index;
        this.label = label;
    }

    @Override
    public String getString() {
        return label;
    }

    @Override
    public int getIndex() {
        return index;
    }

    public static List<String> getEnumStringsAsList() {
        List<String> enumStrings = new ArrayList<>();
        for (IndexingInterface enumValue : values) {
            enumStrings.add(enumValue.getString());
        }
        return enumStrings;
    }
}

public enum FFTMaxFrequency implements IndexingInterface {
    MAX_20 (0, 20, "20 Hz"),
    MAX_40 (1, 40, "40 Hz"),
    MAX_60 (2, 60, "60 Hz"),
    MAX_100 (3, 100, "100 Hz"),
    MAX_120 (4, 120, "120 Hz"),
    MAX_250 (5, 250, "250 Hz"),
    MAX_500 (6, 500, "500 Hz"),
    MAX_800 (7, 800, "800 Hz");

    private final int index;
    private final int value;
    private final String label;
    private static final FFTMaxFrequency[] values = values();

    FFTMaxFrequency(int index, int value, String label) {
        this.index = index;
        this.value = value;
        this.label = label;
    }

    public int getValue() {
        return value;
    }

    @Override
    public String getString() {
        return label;
    }

    @Override
    public int getIndex() {
        return index;
    }

    public static List<String> getEnumStringsAsList() {
        List<String> enumStrings = new ArrayList<>();
        for (IndexingInterface enumValue : values) {
            enumStrings.add(enumValue.getString());
        }
        return enumStrings;
    }

    public int getHighestFrequency() {
        return MAX_800.getValue();
    }
}

public enum FFTVerticalScale implements IndexingInterface {
    SCALE_10 (0, 10, "10 uV"),
    SCALE_50 (1, 50, "50 uV"),
    SCALE_100 (2, 100, "100 uV"),
    SCALE_1000 (3, 1000, "1000 uV");

    private final int index;
    private final int value;
    private final String label;
    private static final FFTVerticalScale[] values = values();

    FFTVerticalScale(int index, int value, String label) {
        this.index = index;
        this.value = value;
        this.label = label;
    }

    public int getValue() {
        return value;
    }

    @Override
    public String getString() {
        return label;
    }

    @Override
    public int getIndex() {
        return index;
    }

    public static List<String> getEnumStringsAsList() {
        List<String> enumStrings = new ArrayList<>();
        for (IndexingInterface enumValue : values) {
            enumStrings.add(enumValue.getString());
        }
        return enumStrings;
    }
}

public enum FFTLogLin implements IndexingInterface {
    LOG (0, "Log"),
    LIN (1, "Linear");

    private final int index;
    private final String label;
    private static final FFTLogLin[] values = values();

    FFTLogLin(int index, String label) {
        this.index = index;
        this.label = label;
    }

    @Override
    public String getString() {
        return label;
    }

    @Override
    public int getIndex() {
        return index;
    }

    public static List<String> getEnumStringsAsList() {
        List<String> enumStrings = new ArrayList<>();
        for (IndexingInterface enumValue : values) {
            enumStrings.add(enumValue.getString());
        }
        return enumStrings;
    }
}