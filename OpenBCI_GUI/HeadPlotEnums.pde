
public enum HeadPlotIntensity implements IndexingInterface {
    INTENSITY_0_02 (0, .02f, "0.02x"),
    INTENSITY_0_2 (1, .2f, "0.2x"),
    INTENSITY_0_5 (2, .5f, "0.5x"),
    INTENSITY_1 (3, 1.0f, "1x"),
    INTENSITY_2 (4, 2.0f, "2x"),
    INTENSITY_4 (5, 4.0f, "4x");

    private final int index;
    private final float value;
    private final String label;
    private static final HeadPlotIntensity[] values = values();

    HeadPlotIntensity(int index, float value, String label) {
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

public enum HeadPlotPolarity implements IndexingInterface {
    PLUS_AND_MINUS (0, "+/-"),
    PLUS (1, "+");

    private final int index;
    private final String label;
    private static final HeadPlotPolarity[] values = values();

    HeadPlotPolarity(int index, String label) {
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

public enum HeadPlotContours implements IndexingInterface {
    ON (0, "ON"),
    OFF (1, "OFF");

    private final int index;
    private final String label;
    private static final HeadPlotContours[] values = values();

    HeadPlotContours(int index, String label) {
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

public enum HeadPlotSmoothing implements IndexingInterface {
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
    private static final HeadPlotSmoothing[] values = values();

    HeadPlotSmoothing(int index, float value, String label) {
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