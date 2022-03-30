# DCS_SAM-Scoot
DCSのSAMの生存性を向上させるスクリプトです。<br>
JDAMなどの爆弾を探知・分析し、危険と判断した場合は逃げる（陣地転換）する機能を実装しました。<br>
![Digital Combat Simulator  Black Shark Screenshot 2022 03 26 - 22 36 11 61](https://user-images.githubusercontent.com/30495755/160241986-a8bb2ef9-00de-4a7b-8340-7c19f8eccc98.png)
注意！<br>
このスクリプトは"移動可能"なSAMが対象です。<br>
SA-2やSA-10といったゲーム上で移動できないSAMは適用できません。<br>

# 使い方<br>
手順は大きく3つです<br>
・スクリプトの導入<br>
・SAMの配置<br>
・WayPointの設定<br>
<br>
サンプルミッションを用意しましたのでそちらを参考にしていただければと思います。<br>
<br>
■スクリプトの導入について<br>
1.ここでluaファイルをダウンロード<br>
2.DCSのエディタで読み込ませる。<br>
  以下の画像を参考にしてください。<br>
  注意：SAM-ScriptではTYPEは"4 MISSION START"ですが、今回は"1 ONCE"です。<br>
  ![Digital Combat Simulator  Black Shark Screenshot 2022 03 26 - 22 23 05 12](https://user-images.githubusercontent.com/30495755/160241496-478e8f33-128d-4eac-8e26-8123174323e6.png)

<br>
■SAMの配置について<br>
SAMを配置したときに、グループ名に"scoot"を含めると今回のスクリプトの対象となります。<br>

<br>
注意点として、<br>
・支援車両を含めないほうが好ましい<br>
    後述しますが、ALARM STATEがREDになっても弾薬補充車両や燃料車両などの車両は停車しません。(スクリプトの機能は問題なし）<br>
・移動の単位はグループ<br>
    本当はユニット単位で動いて欲しいですがゲームの現時点の仕様では無理です...<br>
<br>
■WayPointの設定について<br>
このスクリプトはALARM STATEの挙動を利用しています。<br>
DCSのSAMは、ALARM STATEがREDの時に交戦。<br>
逆に、ALARM STATEがGREENの時に移動先のWayPointが指定されていると移動を開始。<br>
これを活用し、<br>
爆弾が接近<br>
⇒ALARM STATEをGREENに変更<br>
⇒移動<br>
を実現しています。<br>
設定を正しくしないと意図しない挙動を引き起こすのでご注意ください。<br>
<br>
1.WayPointの追加<br>
  移動先を指定してください。<br>
  このときTYPEを"CUSTAM"にしてTEMPLATEを該当するものにすると綺麗に動いてくれます。（サンプルミッションではLINE ABREASTを適用）<br>
  移動速度を上げておくと生存率が上がります。<br>
  
2.Waypointの設定<br>
  次に展開したいPointでALARM STATEをREDに設定。<br>
  複数のポイントで設定することが可能です。<br>
3.最終地点の設定<br>
  Go to wayPointを設定するとWayPointをループさせることができます。<br>

  
# 不具合
・ランチャーが移動しないことがある<br>
  SA-6のランチャーは射撃体勢に入ってしまうとなぜか動きません。<br>
・SA-15に適用すると動き回る<br>
　申し訳ないですが現在対応中です。<br>
<br>
バグや不明点、要望などがございましたらTwitterでご連絡ください。<br>
https://twitter.com/Tama010

# 余談
MK82のRCSは角度によって変化しますが凡そ0.05~0.1㎡らしいです。<br>
  
  

