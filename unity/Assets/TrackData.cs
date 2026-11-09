using System;
using System.Collections.Generic;
using UnityEngine;

/// 1周の中でのコーナー区間。startとendは「1周の中の位置(m)」、
/// severityは外を回った時のスタミナ消費倍率。
[Serializable]
public class CornerZone
{
    public float Start;
    public float End;
    public float Severity;

    public CornerZone(float start, float end, float severity)
    {
        Start = start;
        End = end;
        Severity = severity;
    }
}

/// コース定義。実在の地方競馬場をモデルにする場合は TrackPresets 経由で作る。
public class TrackData
{
    public string TrackName = "";
    public float DistanceM = 1400f;
    public int LaneCount = 4;

    // 1周の距離。周回のない直線コースなら DistanceM と同じ値にする。
    public float LapDistanceM = 1400f;

    public List<CornerZone> CornerZones = new List<CornerZone>();

    // インコース(1レーン寄り)を通り続けることへのペナルティ倍率。0なら無し。
    public float InnerLanePenalty = 0f;

    /// レース上の絶対位置を「1周の中での位置」に変換する。
    /// DistanceMがLapDistanceMの整数倍でない場合、スタート地点は1周の途中になる。
    public float PosInLap(float positionM)
    {
        if (LapDistanceM <= 0f) return positionM;
        float startOffset = Mathf.Repeat(LapDistanceM - Mathf.Repeat(DistanceM, LapDistanceM), LapDistanceM);
        return Mathf.Repeat(startOffset + positionM, LapDistanceM);
    }
}
