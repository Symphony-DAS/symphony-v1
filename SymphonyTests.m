classdef SymphonyTests < matlab.unittest.TestCase
    
    properties
        coreDir
        platform
    end
    
    methods (TestClassSetup)
        
        function classSetup(testCase)
            rootDir = fileparts(mfilename('fullpath'));
            testCase.coreDir = fullfile(rootDir,'symphony-core','src','symphony-core');
            
            if strcmp(computer('arch'), 'win32')
                testCase.platform = 'x86';
            else
                testCase.platform = 'x64';
            end
            
            NET.addAssembly(fullfile(rootDir,'packages','NUnit.2.5.7.10213','tools','lib','nunit.core.dll'));
            NUnit.Core.CoreExtensions.Host.InitializeService();
        end
        
    end
    
    methods (Test)
        
        function runCoreTests(testCase)
            testDir = fullfile(testCase.coreDir,'Symphony.Core.Tests','bin',testCase.platform,'Release');
            
            % Remove HDF5 native dependencies that conflict with Matlab. These will not be installed by the installer.
            if exist(fullfile(testDir,'hdf5_hldll.dll'), 'file')
                delete(fullfile(testDir,'hdf5_hldll.dll'));
            end
            if exist(fullfile(testDir,'hdf5dll.dll'), 'file')
                delete(fullfile(testDir,'hdf5dll.dll'));
            end
            if exist(fullfile(testDir,'szip.dll'), 'file')
                delete(fullfile(testDir,'szip.dll'));
            end
            if exist(fullfile(testDir,'zlib.dll'), 'file')
                delete(fullfile(testDir,'zlib.dll'));
            end
            
            asm = fullfile(testDir,'Symphony.Core.Tests.dll');
            testCase.runNUnitTests(asm);
        end
        
        function runExternalDevicesTests(testCase)
            asm = fullfile(testCase.coreDir,'Symphony.ExternalDevices.Tests','bin',testCase.platform,'Release','Symphony.ExternalDevices.Tests.dll');
            testCase.runNUnitTests(asm);
        end
        
        function runSimulationDAQControllerTests(testCase)
            asm = fullfile(testCase.coreDir,'SimulationDAQController','bin',testCase.platform,'Release','Symphony.SimulationDAQController.dll');
            testCase.runNUnitTests(asm);
        end
        
    end
    
    methods
        
        function runNUnitTests(testCase, assemblyName)
            package = NUnit.Core.TestPackage(assemblyName);
            
            runner = NUnit.Core.RemoteTestRunner();
            runner.Load(package);
            unload = onCleanup(@()runner.Unload());
            
            result = runner.Run(NUnit.Core.NullListener());
            testCase.verifyResult(result);
        end
        
        function verifyResult(testCase, result)
            if result.HasResults
                r = result.Results;
                for i=0:r.Count-1
                    testCase.verifyResult(r.Item(i));
                end
                return;
            end
            
            testCase.verifyTrue(result.IsSuccess || result.ResultState == NUnit.Core.ResultState.Ignored, ...
                sprintf('%s:%s\n%s', char(result.FullName), char(result.ResultState), char(result.Message)));
        end
        
    end
    
end