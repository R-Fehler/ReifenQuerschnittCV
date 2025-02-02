import matlab.unittest.TestRunner
import matlab.unittest.TestSuite
import matlab.unittest.plugins.StopOnFailuresPlugin
addpath Classes
suite = TestSuite.fromClass(?WireTest);
runner = TestRunner.withTextOutput;

runner.addPlugin(StopOnFailuresPlugin)
result = runner.run(suite);