using System;

/// 馬1頭分の能力値。実在の競走馬・騎手とは一切関係のない架空の値。
[Serializable]
public class HorseStats
{
    public string DisplayName = "";
    public string JockeyName = "";

    public int Speed = 50;   // 1-100: トップスピードの高さ
    public int Stamina = 50; // 1-100: スタミナの多さ(バテにくさ)
    public int Power = 50;   // 1-100: 加速力・瞬発力
    public int Guts = 50;    // 1-100: 終盤でどれだけ踏ん張れるか

    // 脚質: NIGE(逃げ) / SENKO(先行) / SASHI(差し) / OIKOMI(追込)
    public string RunningStyle = "SENKO";
}
