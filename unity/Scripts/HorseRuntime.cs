using UnityEngine;

/// レース中の1頭分の可変状態(位置・速度・スタミナ等)とステップ更新ロジック。
/// MonoBehaviourではない素のC#クラスなので、シーンが無くてもテストできる。
public class HorseRuntime
{
    public HorseStats Stats;

    public float PositionM = 0f;
    public float SpeedMps = 0f;
    public float StaminaCur = 0f;
    public float StaminaMax = 0f;
    public float LaneCur;

    public bool Finished = false;
    public float FinishTime = -1f;
    public int Rank = -1;

    public HorseRuntime(HorseStats stats, float startLane = 2f)
    {
        Stats = stats;
        StaminaMax = Mathf.Lerp(60f, 100f, stats.Stamina / 100f);
        StaminaCur = StaminaMax;
        LaneCur = startLane;
    }

    public float BaseSpeedMps()
    {
        return Mathf.Lerp(15f, 19f, Stats.Speed / 100f);
    }

    public float AccelMps2()
    {
        return Mathf.Lerp(3f, 6.5f, Stats.Power / 100f);
    }

    /// そのコーナーがどれだけきついか(外を回った時のスタミナ消費倍率)。直線なら0。
    public float CornerSeverity(TrackData track)
    {
        float p = track.PosInLap(PositionM);
        foreach (var zone in track.CornerZones)
        {
            if (p >= zone.Start && p < zone.End) return zone.Severity;
        }
        return 0f;
    }

    /// 1ステップ進める。
    /// effort: 0.3(抑える)〜1.0(全力)の継続操作値
    /// laneTarget: 目標レーン(1=内 〜 lane_count=外)
    /// speedCap: 前の馬が詰まっている場合の速度上限(負値なら無効)
    /// raceProgress: レース全体の進行度(0.0〜1.0、終盤ボーナス判定に使用)
    public void Step(float dt, float effort, float laneTarget, TrackData track, float speedCap, float raceProgress)
    {
        if (Finished) return;

        effort = Mathf.Clamp(effort, 0.3f, 1f);

        float targetSpeed = BaseSpeedMps() * (0.55f + 0.45f * effort);

        // 終盤の踏ん張り(ガッツ)ボーナス。スタミナが残っている時だけ効く
        if (raceProgress >= 0.85f && StaminaCur > 5f)
        {
            targetSpeed *= 1f + (Stats.Guts / 100f) * 0.08f;
        }

        // スタミナ切れ(バテ)
        if (StaminaCur <= 0f)
        {
            targetSpeed *= 0.6f;
        }

        if (speedCap >= 0f)
        {
            targetSpeed = Mathf.Min(targetSpeed, speedCap);
        }

        float accel = AccelMps2();
        float diff = targetSpeed - SpeedMps;
        SpeedMps += Mathf.Clamp(diff, -accel * dt, accel * dt);
        SpeedMps = Mathf.Max(SpeedMps, 0f);

        // スタミナ消費。コーナーで外(3,4レーン)を回ると消費が増える
        float severity = CornerSeverity(track);
        float cornerPenalty = 1f;
        if (severity > 0f && LaneCur >= 3f) cornerPenalty = severity;

        // インコースの砂が深い等、特定コースの特徴によるペナルティ
        float innerPenalty = 1f;
        if (track.InnerLanePenalty > 0f && LaneCur < 1.5f) innerPenalty = 1f + track.InnerLanePenalty;

        float drain = (effort * effort) * 1.8f * cornerPenalty * innerPenalty * dt;
        StaminaCur = Mathf.Max(StaminaCur - drain, 0f);
        if (effort <= 0.4f)
        {
            StaminaCur = Mathf.Min(StaminaCur + 2f * dt, StaminaMax);
        }

        // レーン変更。1秒あたり最大1.5レーンまで
        float laneSpeed = 1.5f * dt;
        LaneCur += Mathf.Clamp(laneTarget - LaneCur, -laneSpeed, laneSpeed);
        LaneCur = Mathf.Clamp(LaneCur, 1f, track.LaneCount);

        PositionM += SpeedMps * dt;

        if (PositionM >= track.DistanceM)
        {
            PositionM = track.DistanceM;
            Finished = true;
        }
    }
}
