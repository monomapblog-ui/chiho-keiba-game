using System.Collections.Generic;
using UnityEngine;

/// プレイ可能なシーンを実行時にすべてコード側で組み立てるブートストラップ。
/// 空のGameObjectにこのスクリプトをアタッチして再生するだけで動く。
///
/// 見た目はまだ仮(直方体のプレースホルダー)。本格的な3Dモデルへの
/// 差し替えは別途。カメラはプレイヤーを追従するシンプルなチェイスカメラ。
public class RaceBootstrap : MonoBehaviour
{
    private const float TrackUnitsPerMeter = 0.05f; // 1400m -> 70 Unityユニット
    private const float LaneSpacing = 2.5f;

    private static readonly Color[] HorseColors = new Color[]
    {
        new Color(0.95f, 0.15f, 0.15f), // プレイヤー: 赤
        new Color(0.95f, 0.75f, 0.1f),  // CPU1: 黄
        new Color(0.15f, 0.75f, 0.95f), // CPU2: 水色
        new Color(0.5f, 0.9f, 0.25f),   // CPU3: 緑
    };

    private RaceWorld world;
    private readonly System.Random rng = new System.Random();

    private float playerEffort = 0.65f;
    private float playerLane = 1f; // プレイヤーは1番ゲート(内側)スタート
    private bool raceFinished = false;

    private readonly List<GameObject> horseObjects = new List<GameObject>();
    private Camera cam;

    void Start()
    {
        BuildWorld();
        BuildGround();
        BuildHorses();
        SetupCamera();
        SetupLight();
    }

    void BuildWorld()
    {
        var track = TrackPresets.Kochi();
        var roster = new List<HorseStats>
        {
            new HorseStats { DisplayName = "カゼノハヤテ", JockeyName = "小峰 隼人", Speed = 72, Stamina = 60, Power = 68, Guts = 55, RunningStyle = "NIGE" },
            new HorseStats { DisplayName = "ゴールドブリーズ", JockeyName = "芦田 蓮", Speed = 65, Stamina = 70, Power = 60, Guts = 65, RunningStyle = "SENKO" },
            new HorseStats { DisplayName = "クロシオキング", JockeyName = "最上 龍馬", Speed = 60, Stamina = 75, Power = 58, Guts = 72, RunningStyle = "SASHI" },
            new HorseStats { DisplayName = "トサノツバサ", JockeyName = "日向 景虎", Speed = 58, Stamina = 68, Power = 70, Guts = 60, RunningStyle = "OIKOMI" },
        };
        world = new RaceWorld(track, roster);
    }

    void BuildGround()
    {
        var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
        ground.name = "Track";

        float lengthUnits = world.Track.DistanceM * TrackUnitsPerMeter;
        float widthUnits = world.Track.LaneCount * LaneSpacing + 4f;

        // Unity標準のPlaneは初期状態で10x10なので、10で割ってスケールを合わせる
        ground.transform.localScale = new Vector3(lengthUnits / 10f, 1f, widthUnits / 10f);
        ground.transform.position = new Vector3(lengthUnits / 2f, 0f, 0f);

        ground.GetComponent<Renderer>().material = MakeColorMaterial(new Color(0.45f, 0.32f, 0.18f));
    }

    void BuildHorses()
    {
        for (int i = 0; i < world.Horses.Count; i++)
        {
            // 本物の3Dモデルへの差し替えは別途。今は進行方向に長い箱で代用。
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.name = world.Horses[i].Stats.DisplayName;
            go.transform.localScale = new Vector3(1.2f, 0.6f, 0.5f);
            go.GetComponent<Renderer>().material = MakeColorMaterial(HorseColors[i % HorseColors.Length]);
            horseObjects.Add(go);
        }
    }

    void SetupCamera()
    {
        cam = Camera.main;
        if (cam == null)
        {
            var camGo = new GameObject("MainCamera");
            cam = camGo.AddComponent<Camera>();
            camGo.tag = "MainCamera";
        }
    }

    void SetupLight()
    {
        if (Object.FindFirstObjectByType<Light>() != null) return;
        var lightGo = new GameObject("Directional Light");
        var light = lightGo.AddComponent<Light>();
        light.type = LightType.Directional;
        lightGo.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
    }

    /// URP/標準パイプラインどちらでも(できるだけ)ピンク色の未対応マテリアルに
    /// ならないよう、シェーダーを順番に探して使えるものを使う。
    Material MakeColorMaterial(Color c)
    {
        Shader shader = Shader.Find("Universal Render Pipeline/Unlit");
        if (shader == null) shader = Shader.Find("Unlit/Color");
        if (shader == null) shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null) shader = Shader.Find("Standard");

        var mat = new Material(shader);
        if (mat.HasProperty("_BaseColor")) mat.SetColor("_BaseColor", c);
        if (mat.HasProperty("_Color")) mat.SetColor("_Color", c);
        return mat;
    }

    void Update()
    {
        if (world == null || raceFinished) return;

        HandleInput();

        float progress = world.RaceProgress();
        float[] efforts = new float[world.Horses.Count];
        float[] lanes = new float[world.Horses.Count];

        for (int i = 0; i < world.Horses.Count; i++)
        {
            if (i == 0)
            {
                efforts[i] = playerEffort;
                lanes[i] = playerLane;
            }
            else
            {
                var d = AIController.Decide(world.Horses[i], world.Track, progress, rng);
                efforts[i] = d.Effort;
                lanes[i] = d.Lane;
            }
        }

        world.StepAll(Time.deltaTime, efforts, lanes);
        UpdateVisuals();

        if (world.AllFinished() && !raceFinished)
        {
            raceFinished = true;
        }
    }

    void HandleInput()
    {
        float dt = Time.deltaTime;
        bool push = Input.GetKey(KeyCode.UpArrow) || Input.GetKey(KeyCode.W);
        bool back = Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.S);
        bool left = Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A);
        bool right = Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D);

        if (push) playerEffort = Mathf.Min(playerEffort + dt * 1.5f, 1f);
        else if (back) playerEffort = Mathf.Max(playerEffort - dt * 1.5f, 0.3f);
        else playerEffort = Mathf.Lerp(playerEffort, 0.65f, dt);

        if (left) playerLane = Mathf.Max(playerLane - dt * 2f, 1f);
        else if (right) playerLane = Mathf.Min(playerLane + dt * 2f, world.Track.LaneCount);
    }

    void UpdateVisuals()
    {
        for (int i = 0; i < world.Horses.Count; i++)
        {
            var h = world.Horses[i];
            var go = horseObjects[i];
            float x = h.PositionM * TrackUnitsPerMeter;
            float z = (h.LaneCur - (world.Track.LaneCount + 1) / 2f) * LaneSpacing;
            go.transform.position = new Vector3(x, 0.3f, z);
        }

        if (cam != null && horseObjects.Count > 0)
        {
            Vector3 playerPos = horseObjects[0].transform.position;
            Vector3 desired = playerPos + new Vector3(-6f, 4f, 0f);
            cam.transform.position = Vector3.Lerp(cam.transform.position, desired, 0.1f);
            cam.transform.LookAt(playerPos + Vector3.right * 3f + Vector3.up * 0.5f);
        }
    }

    void OnGUI()
    {
        if (world == null) return;

        var style = new GUIStyle(GUI.skin.label) { fontSize = 16 };

        int y = 10;
        for (int i = 0; i < world.Horses.Count; i++)
        {
            var h = world.Horses[i];
            style.normal.textColor = HorseColors[i % HorseColors.Length];
            string tag = i == 0 ? " (あなた)" : "";
            GUI.Label(new Rect(10, y, 760, 24),
                $"{h.Stats.DisplayName}{tag}  速度:{h.SpeedMps:F1}m/s  スタミナ:{h.StaminaCur:F0}/{h.StaminaMax:F0}  距離:{h.PositionM:F0}/{world.Track.DistanceM:F0}m",
                style);
            y += 22;
        }

        style.normal.textColor = Color.white;
        GUI.Label(new Rect(10, y + 10, 900, 24),
            "↑/W: 押す(効果アップ/スタミナ消費大)  ↓/S: 抑える(スタミナ回復)  ←→ or A/D: レーン変更",
            style);

        if (raceFinished)
        {
            string result = "【結果】\n";
            for (int i = 0; i < world.FinishOrder.Count; i++)
            {
                int idx = world.FinishOrder[i];
                var h = world.Horses[idx];
                string tag = idx == 0 ? " (あなた)" : "";
                result += $"{i + 1}着: {h.Stats.DisplayName}{tag} ({h.FinishTime:F2}秒)\n";
            }

            var resultStyle = new GUIStyle(GUI.skin.label) { fontSize = 20 };
            resultStyle.normal.textColor = Color.white;
            GUI.Label(new Rect(Screen.width / 2 - 150, 40, 400, 300), result, resultStyle);
        }
    }
}
