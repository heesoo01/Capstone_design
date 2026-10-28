classdef MuJoCoJointSys < matlab.System
    % MuJoCoJointSys  Simulink <-> MuJoCo 연동 시험용 기계 블록 (MATLAB System 블록, Interpreted Execution)
    %   입력  tau : 관절 입력 토크 [N*m] (기어 이후, 5주차 3-2 의 GNt 출력)
    %   출력  q, qd : 관절 각도 [rad], 각속도 [rad/s]
    %   매 물리 간격 Dt(25 us)마다 입력 토크를 한 구간 동안 유지하고 MuJoCo(python, scripts/cosim/mj_cosim.py)를 한 스텝 진행한다.
    %   출력은 구간 시작 상태(직접 관통 없음)이며, 민혁 MuJoCo 결합과 같은 순서다:
    %   구간 시작의 상태로 전기·제어가 토크를 정하고, 그 토크를 구간 동안 유지해 MuJoCo 가 적분한다.
    properties (Nontunable)
        Dt = 25e-6      % 물리 간격 [s]
    end
    properties (Access = private)
        sim
        qv = 0
        qdv = 0
    end
    methods (Access = protected)
        function setupImpl(obj)
            here = fileparts(which('MuJoCoJointSys'));
            sp = py.sys.path;
            if ~logical(py.list(sp).count(here))
                sp.insert(int32(0), here);
            end
            mod = py.importlib.import_module('mj_cosim');
            mod = py.importlib.reload(mod);
            obj.sim = mod.Sim(obj.Dt);
            s = double(obj.sim.state());
            obj.qv = s(1); obj.qdv = s(2);
        end
        function [q, qd] = outputImpl(obj, varargin)
            q = obj.qv; qd = obj.qdv;
        end
        function updateImpl(obj, tau)
            r = double(obj.sim.step(double(tau)));
            obj.qv = r(1); obj.qdv = r(2);
        end
        function resetImpl(obj)
            s = double(obj.sim.state());
            obj.qv = s(1); obj.qdv = s(2);
        end
        function flag = isInputDirectFeedthroughImpl(~, varargin)
            flag = false;
        end
        function n = getNumInputsImpl(~)
            n = 1;
        end
        function n = getNumOutputsImpl(~)
            n = 2;
        end
        function name = getInputNamesImpl(~)
            name = 'tau';
        end
        function [n1, n2] = getOutputNamesImpl(~)
            n1 = 'q'; n2 = 'qd';
        end
        function st = getSampleTimeImpl(obj)
            st = createSampleTime(obj, 'Type', 'Discrete', 'SampleTime', obj.Dt);
        end
        function [s1, s2] = getOutputSizeImpl(~)
            s1 = [1 1]; s2 = [1 1];
        end
        function [t1, t2] = getOutputDataTypeImpl(~)
            t1 = 'double'; t2 = 'double';
        end
        function [c1, c2] = isOutputComplexImpl(~)
            c1 = false; c2 = false;
        end
        function [f1, f2] = isOutputFixedSizeImpl(~)
            f1 = true; f2 = true;
        end
    end
end
