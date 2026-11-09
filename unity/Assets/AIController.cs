using UnityEngine;

/// CPU(対戦相手)の馬の操作を脚質に応じて自動で決める、簡易な意思決定ロジック。
public static class AIController
{
    public struct Decision
    {
        public float Effort;
        public float Lane;
    }

    public static Decision Decide(HorseRuntime h, TrackData track, float progress, System.Random rng)
    {
        string style = h.Stats.RunningStyle;
        float effort;
        float baseLane;

        switch (style)
        {
            case "NIGE":
                effort = progress < 0.6f ? 0.85f : (progress < 0.85f ? 0.55f : 0.9f);
                baseLane = 1.3f; // 逃げ: 内側のインコースを突く
                break;
            case "SENKO":
                effort = progress < 0.75f ? 0.7f : 0.9f;
                baseLane = 1.8f; // 先行: ややインコース寄り
                break;
            case "SASHI":
                effort = progress < 0.7f ? 0.55f : 0.95f;
                baseLane = 2.6f; // 差し: やや外側から勝負
                break;
            case "OIKOMI":
                effort = progress < 0.8f ? 0.45f : 1.0f;
                baseLane = 3.2f; // 追込: 外側から大外一気を狙う
                break;
            default:
                effort = 0.7f;
                baseLane = 2f;
                break;
        }

        effort += (float)(rng.NextDouble() * 0.1 - 0.05);
        effort = Mathf.Clamp(effort, 0.3f, 1f);

        // 終盤、インコースの消耗ペナルティが大きいコースでは外に膨らむ判断をする
        if (track.InnerLanePenalty > 0f && progress > 0.3f)
        {
            baseLane = Mathf.Max(baseLane, 1.8f);
        }

        float laneTarget = Mathf.Clamp(
            baseLane + (float)(rng.NextDouble() * 0.5 - 0.25),
            1f, track.LaneCount);

        return new Decision { Effort = effort, Lane = laneTarget };
    }
}
