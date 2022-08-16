unit Threads;

interface

uses
  System.Classes, Winapi.Windows,
  System.SysUtils;

type

  TMethod = procedure of object;

  TCoreThread = class(TThread)
  private
    ThreadMethod:TMethod;
    SleepInterval: Uint16;
  protected
    procedure Execute; override;
  public
    procedure SetThreadMethod(Method:TMethod);
    procedure SetSleepInterval(Value:UInt16);
  end;

  TThreadContainer = class
  private
    TCount:UInt16;
    T1:array[0..64] of TCoreThread;
  public
    constructor Create(Method:TMethod);
    destructor Destroy; override;
    function GetTCount: Uint16;
  end;

  function GetNumberOfProcessors: UInt16;

  var
    FT:Int64;
    ErrorsCounter:UInt32;

implementation

{
  ThreadContainer := TThreadContainer.Create(Method);
}

function GetNumberOfProcessors: UInt16;
  var
     SIRecord: TSystemInfo;
  begin
     GetSystemInfo(SIRecord);
     Result := SIRecord.dwNumberOfProcessors;
  end;

{ TCoreThread }

procedure TCoreThread.Execute;
  var
    F:Int64;
  begin
    inherited;
    repeat
      Synchronize(Self.ThreadMethod);
      {    //unsafe work. vcl canvas crash;
      QueryPerformanceCounter(F);
      FT := F;
      if FT = F then
        try
          Self.ThreadMethod;
        except
          inc(ErrorsCounter);
          Synchronize(Self.ThreadMethod);
          Continue
        end;
      }
      System.YieldProcessor;
      SleepEx(Self.SleepInterval,False);
    until Terminated;
  end;

procedure TCoreThread.SetSleepInterval(Value: UInt16);
  begin
    Self.SleepInterval := Value;
  end;

procedure TCoreThread.SetThreadMethod(Method: TMethod);
  begin
    Self.ThreadMethod := Method;
  end;

{ TThreadContainer }

constructor TThreadContainer.Create(Method:TMethod);
  var
    I:Uint16;
  begin
    TCount  := GetNumberOfProcessors;
    for I   := 0 to TCount - 1 do
      begin
        T1[I] := TCoreThread.Create(True);
        T1[I].SetThreadMethod(Method);
        T1[I].Priority := tpIdle;
        T1[I].SetSleepInterval(0);
        T1[I].Start;
      end;
  end;

destructor TThreadContainer.Destroy;
  var
    I:Uint16;
  begin
    for I := 0 to TCount do T1[I].Free;
  end;

function TThreadContainer.GetTCount: Uint16;
  begin
    Result := TCount;
  end;

end.
