
public enum BPAutoClean implements IndexingInterface
{
    ON (0, "On"),
    OFF (1, "Off");

    private int index;
    private String label;

    BPAutoClean(int _index, String _label) {
        this.index = _index;
        this.label = _label;
    }

    @Override
    public String getString() {
        return label;
    }

    @Override
    public int getIndex() {
        return index;
    }
}

public enum BPAutoCleanThreshold implements IndexingInterface
{
    FORTY (0, 40f, "40 uV"),
    FIFTY (1, 50f, "50 uV"),
    SIXTY (2, 60f, "60 uV"),
    SEVENTY (3, 70f, "70 uV"),
    EIGHTY (4, 80f, "80 uV"),
    NINETY (5, 90f, "90 uV"),
    ONE_HUNDRED(6, 100f, "100 uV");

    private int index;
    private float value;
    private String label;

    BPAutoCleanThreshold(int _index, float _value, String _label) {
        this.index = _index;
        this.value = _value;
        this.label = _label;
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
}

public enum BPAutoCleanTimer implements IndexingInterface
{
    HALF_SECOND (0, 500, ".5 sec"),
    ONE_SECOND (1, 1000, "1 sec"),
    THREE_SECONDS (2, 2000, "3 sec"),
    FIVE_SECONDS (3, 5000, "5 sec"),
    TEN_SECONDS (4, 10000, "10 sec"),
    TWENTY_SECONDS (5, 20000, "20 sec"),
    THIRTY_SECONDS(6, 30000, "30 sec");

    private int index;
    private float value;
    private String label;

    BPAutoCleanTimer(int _index, float _value, String _label) {
        this.index = _index;
        this.value = _value;
        this.label = _label;
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
}