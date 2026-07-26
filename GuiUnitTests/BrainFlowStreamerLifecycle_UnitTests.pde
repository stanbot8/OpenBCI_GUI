import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

class FakeBrainFlowStream implements BrainFlowStream {
    String activeStreamer = "";
    int deleteCount = 0;
    int startCount = 0;
    boolean boardStreaming = false;
    boolean failNextDelete = false;
    boolean failNextStart = false;
    boolean failNextStop = false;

    public void startStream(int bufferSize, String streamer) throws Exception {
        if (boardStreaming || (!streamer.isEmpty() && !activeStreamer.isEmpty())) {
            throw new Exception("duplicate stream");
        }

        startCount++;
        activeStreamer = streamer;
        boardStreaming = true;
        if (failNextStart) {
            failNextStart = false;
            throw new Exception("start failed");
        }
    }

    public void stopStream() throws Exception {
        if (failNextStop) {
            failNextStop = false;
            throw new Exception("stop failed");
        }
        boardStreaming = false;
    }

    public void deleteStreamerIfPresent(String streamer) throws Exception {
        if (boardStreaming) {
            throw new Exception("delete while streaming");
        }
        deleteCount++;
        if (failNextDelete) {
            failNextDelete = false;
            throw new Exception("delete failed");
        }
        if (activeStreamer.equals(streamer)) {
            activeStreamer = "";
        }
    }
}

public static class BrainFlowStreamerLifecycle_UnitTests {
    private static final String NETWORK_STREAMER = "streaming_board://225.1.1.1:6677";

    private FakeBrainFlowStream stream;
    private BrainFlowStreamerLifecycle lifecycle;

    @Before
    public void setUp() {
        stream = currentApplet.new FakeBrainFlowStream();
        lifecycle = currentApplet.new BrainFlowStreamerLifecycle(stream);
    }

    @Test
    public void restartRemovesTheOldNetworkStreamer() throws Exception {
        lifecycle.start(NETWORK_STREAMER);
        lifecycle.stop();
        lifecycle.start(NETWORK_STREAMER);

        Assert.assertEquals(2, stream.startCount);
        Assert.assertEquals(1, stream.deleteCount);
        Assert.assertEquals(NETWORK_STREAMER, stream.activeStreamer);
    }

    @Test
    public void restartReplacesAChangedFileStreamer() throws Exception {
        lifecycle.start("file://recording-0.csv:w");
        lifecycle.stop();
        lifecycle.start("file://recording-1.csv:w");

        Assert.assertEquals("file://recording-1.csv:w", stream.activeStreamer);
    }

    @Test
    public void startRetriesCleanupBeforeItAddsAnotherStreamer() throws Exception {
        lifecycle.start(NETWORK_STREAMER);
        stream.failNextDelete = true;

        try {
            lifecycle.stop();
            Assert.fail("The cleanup must fail.");
        } catch (Exception expected) {
        }

        lifecycle.start(NETWORK_STREAMER);

        Assert.assertEquals(2, stream.deleteCount);
        Assert.assertEquals(2, stream.startCount);
    }

    @Test
    public void failedStartRemovesItsPartialStreamer() throws Exception {
        stream.failNextStart = true;

        try {
            lifecycle.start(NETWORK_STREAMER);
            Assert.fail("The start must fail.");
        } catch (Exception expected) {
        }

        Assert.assertFalse(stream.boardStreaming);
        lifecycle.start(NETWORK_STREAMER);

        Assert.assertEquals(2, stream.startCount);
        Assert.assertEquals(1, stream.deleteCount);
    }

    @Test
    public void failedStartCleanupFinishesBeforeAnotherStart() throws Exception {
        stream.failNextStart = true;
        stream.failNextStop = true;

        try {
            lifecycle.start(NETWORK_STREAMER);
            Assert.fail("The start must fail.");
        } catch (Exception expected) {
        }

        lifecycle.start(NETWORK_STREAMER);

        Assert.assertEquals(2, stream.startCount);
        Assert.assertEquals(1, stream.deleteCount);
        Assert.assertTrue(stream.boardStreaming);
    }

    @Test
    public void failedStopBlocksAnotherStart() throws Exception {
        lifecycle.start(NETWORK_STREAMER);
        stream.failNextStop = true;

        try {
            lifecycle.stop();
            Assert.fail("The stop must fail.");
        } catch (Exception expected) {
        }

        lifecycle.start(NETWORK_STREAMER);

        Assert.assertTrue(lifecycle.isStreaming());
        Assert.assertEquals(1, stream.startCount);
        Assert.assertEquals(0, stream.deleteCount);
    }
}
