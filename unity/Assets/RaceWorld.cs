using System.Collections.Generic;
using System.Linq;
using UnityEngine;

/// レース全体(複数頭)の進行管理。前の馬が詰まっている場合の速度頭打ち(ブロッキング)も
/// ここで解決してから各馬のStep()を呼ぶ。
public class RaceWorld
{
    public const float MinGapM = 1.2f;
    public const float LaneBlockThreshold = 0.8f;

    public TrackData Track;
    public List<HorseRuntime> Horses = new List<HorseRuntime>();
    public float Elapsed = 0f;
    public List<int> FinishOrder = new List<int>();

    public RaceWorld(TrackData track, List<HorseStats> roster)
    {
        Track = track;
        for (int i = 0; i < roster.Count; i++)
        {
            // 発走ゲート番号をそのままスタート時のレーンにする(1番枠は内側、など)
            float gate = 1f + (i % track.LaneCount);
            Horses.Add(new HorseRuntime(roster[i], gate));
        }
    }

    public bool AllFinished()
    {
        return Horses.All(h => h.Finished);
    }

    public float RaceProgress()
    {
        float total = 0f;
        foreach (var h in Horses) total += h.PositionM / Track.DistanceM;
        return total / Horses.Count;
    }

    public void StepAll(float dt, float[] efforts, float[] laneTargets)
    {
        Elapsed += dt;
        float progress = RaceProgress();

        float[] caps = new float[Horses.Count];
        for (int i = 0; i < caps.Length; i++) caps[i] = -1f;

        // 位置が前な馬から順に並べ、同レーンで詰まっていれば後ろの馬の速度をキャップする
        var order = Enumerable.Range(0, Horses.Count)
            .OrderByDescending(i => Horses[i].PositionM)
            .ToList();

        for (int rankIdx = 0; rankIdx < order.Count; rankIdx++)
        {
            int i = order[rankIdx];
            var h = Horses[i];
            if (h.Finished) continue;

            for (int rankIdx2 = 0; rankIdx2 < rankIdx; rankIdx2++)
            {
                int j = order[rankIdx2];
                var ahead = Horses[j];
                if (ahead.Finished) continue;

                float gap = ahead.PositionM - h.PositionM;
                float laneGap = Mathf.Abs(ahead.LaneCur - h.LaneCur);
                if (gap >= 0f && gap < MinGapM && laneGap < LaneBlockThreshold)
                {
                    caps[i] = ahead.SpeedMps;
                }
            }
        }

        for (int i = 0; i < Horses.Count; i++)
        {
            Horses[i].Step(dt, efforts[i], laneTargets[i], Track, caps[i], progress);
        }

        for (int i = 0; i < Horses.Count; i++)
        {
            var h = Horses[i];
            if (h.Finished && h.FinishTime < 0f)
            {
                h.FinishTime = Elapsed;
                FinishOrder.Add(i);
                h.Rank = FinishOrder.Count;
            }
        }
    }
}
