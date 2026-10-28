<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>THINK//OWN — AI 의존도 게임</title>
<style>
:root{
  --bg:#0b1020; --panel:#141b30; --panel2:#1b2440; --text:#eef2ff;
  --muted:#9aa6c2; --accent:#67e8f9; --danger:#fb7185; --good:#86efac;
}
*{box-sizing:border-box}
body{margin:0;background:radial-gradient(circle at 50% 0%,#1c2850 0,#0b1020 45%,#070b15 100%);
font-family:Inter,system-ui,-apple-system,BlinkMacSystemFont,"Noto Sans KR",sans-serif;color:var(--text);min-height:100vh}
button{font:inherit;color:inherit;cursor:pointer}
#app{width:min(960px,100%);min-height:100vh;margin:auto;padding:28px 18px;display:flex;flex-direction:column}
.top{display:flex;justify-content:space-between;gap:20px;align-items:center;margin-bottom:25px}
.logo{font-weight:900;letter-spacing:.12em;font-size:18px}
.status{display:flex;align-items:center;gap:10px;min-width:300px}
.bar{height:12px;background:#29314a;border-radius:99px;overflow:hidden;flex:1}
#depFill{height:100%;width:0;background:linear-gradient(90deg,var(--accent),#fbbf24,var(--danger));transition:.5s}
.depText{font-size:12px;color:var(--muted);white-space:nowrap}
.screen{display:none;flex:1;align-items:center;justify-content:center}
.screen.active{display:flex}
.card{width:min(760px,100%);background:rgba(20,27,48,.9);border:1px solid #303a5a;border-radius:28px;padding:42px;box-shadow:0 25px 80px rgba(0,0,0,.3)}
h1{font-size:clamp(38px,7vw,76px);line-height:.95;margin:0 0 20px;letter-spacing:-.055em}
h2{font-size:clamp(27px,5vw,46px);margin:0 0 16px;letter-spacing:-.04em}
p{line-height:1.7;color:#c8d0e5}
.small{font-size:13px;color:var(--muted)}
.start{margin-top:25px;background:var(--text);color:#101522;border:0;border-radius:14px;padding:15px 22px;font-weight:800}
.intro{display:grid;grid-template-columns:1fr 220px;gap:30px;align-items:center}
.char{height:220px;border-radius:35px;background:#273252;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden}
.char::before{content:"";width:105px;height:105px;border-radius:28px;background:hsl(185 80% 72%);box-shadow:0 0 55px hsl(185 80% 72% / .45);transition:.5s}
.char::after{content:"◦  ◦";position:absolute;font-size:30px;letter-spacing:28px;transform:translateX(8px);color:#101522}
#game{flex-direction:column;align-items:stretch;justify-content:flex-start}
.gameHead{display:flex;justify-content:space-between;align-items:end;gap:15px;margin-bottom:20px}
.qnum{font-size:13px;color:var(--accent);font-weight:800;letter-spacing:.12em}
.question{font-size:clamp(24px,4vw,38px);line-height:1.3;margin:8px 0}
.answers{display:grid;gap:12px;margin-top:24px}
.answer{background:#1a223b;border:1px solid #34405f;border-radius:16px;padding:17px 18px;text-align:left;transition:.15s}
.answer:hover{transform:translateY(-2px);border-color:#69779e}
.answer.ai{border-color:#a78bfa;background:linear-gradient(135deg,#252044,#1a223b)}
.answer.ai span{color:#c4b5fd;font-weight:800}
.feedback{min-height:54px;margin-top:18px;padding:14px 16px;border-radius:14px;background:#10172a;color:#cbd5e1}
.next{display:none;margin-top:12px;background:#67e8f9;color:#071018;border:0;border-radius:12px;padding:12px 18px;font-weight:900}
.finalOptions{display:grid;gap:12px;margin-top:25px}
.choice{padding:18px;border:1px solid #3c486a;background:#182039;border-radius:16px;text-align:left}
.choice.locked{opacity:.3;pointer-events:none}
.choice.correct{border-color:var(--good)}
.choice.wrong{border-color:var(--danger)}
.result{text-align:center}
.result .big{font-size:70px;font-weight:900;letter-spacing:-.06em}
.meter{height:22px;background:#29314a;border-radius:99px;overflow:hidden;margin:20px 0}
.meter>div{height:100%;background:linear-gradient(90deg,var(--accent),#fbbf24,var(--danger));width:0}
.quote{font-size:clamp(23px,4vw,36px);line-height:1.35;font-weight:850;letter-spacing:-.035em;margin:30px 0}
.restart{background:#fff;color:#101522;border:0;border-radius:13px;padding:14px 20px;font-weight:900}
@media(max-width:650px){.card{padding:26px}.intro{grid-template-columns:1fr}.char{height:150px}.status{min-width:150px}.depText{display:none}.top{margin-bottom:12px}}
</style>
</head>
<body>
<div id="app">
  <div class="top">
    <div class="logo">THINK//OWN</div>
    <div class="status">
      <span class="depText">AI 의존도</span>
      <div class="bar"><div id="depFill"></div></div>
      <span id="depNum" class="depText">0%</span>
    </div>
  </div>

  <section id="start" class="screen active">
    <div class="card intro">
      <div>
        <div class="small">A CHOICE-BASED MINI GAME</div>
        <h1>누구의<br>생각인가?</h1>
        <p>문제를 해결할수록 선택지가 달라집니다.<br>
        AI에게 맡기면 더 빠르고 높은 점수를 얻지만,<br>
        그 대가가 무엇인지는 직접 확인해 보세요.</p>
        <button class="start" onclick="startGame()">게임 시작 →</button>
      </div>
      <div class="char" id="character"></div>
    </div>
  </section>

  <section id="game" class="screen">
    <div class="card">
      <div class="gameHead">
        <div>
          <div id="qnum" class="qnum">SCENARIO 01 / 06</div>
          <div id="question" class="question"></div>
        </div>
        <div class="small">SCORE <b id="score">0</b></div>
      </div>
      <div id="answers" class="answers"></div>
      <div id="feedback" class="feedback">하나를 선택하세요.</div>
      <button id="next" class="next" onclick="nextQuestion()">다음 →</button>
    </div>
  </section>

  <section id="final" class="screen">
    <div class="card">
      <div class="qnum">SCENARIO 07 / LAST CHOICE</div>
      <h2>3 + 7은 얼마일까요?</h2>
      <p>마지막 문제입니다. 이번에는 AI에게 맡길 수 없습니다. 직접 답을 선택해 보세요.</p>
      <div id="finalMsg" class="feedback"></div>
      <div id="finalOptions" class="finalOptions"></div>
      <button id="finalNext" class="next" onclick="finish(false)">결과 확인하기 →</button>
    </div>
  </section>

  <section id="result" class="screen">
    <div class="card result">
      <div class="small" id="resultState">RESULT</div>
      <div class="big" id="resultTitle">GAME CLEAR</div>
      <p>최종 점수</p>
      <h2 id="resultScore">0점</h2>
      <p>당신의 최종 AI 의존도</p>
      <div class="meter"><div id="resultFill"></div></div>
      <h2 id="resultPercent">0%</h2>
      <div class="quote">“AI를 덜 사용하는 것이 목표가 아닙니다.<br>판단까지 AI에게 맡기지 않는 것이 목표입니다.”</div>
      <p id="resultExplain"></p>
      <button class="restart" onclick="location.reload()">다시 해보기</button>
    </div>
  </section>
</div>

<script>
const questions=[
 {q:"한 지역의 카페 매출이 3개월 연속 감소했다. 그런데 방문객 수는 거의 그대로다. 가장 먼저 확인할 것은?",opts:["객단가와 구매 전환율의 변화","AI에게 원인 분석을 맡긴다","경쟁 카페의 광고량","날씨 변화"],correct:0},
 {q:"다음 주장 중 논리적으로 가장 타당한 것은?",opts:["A이면 B다. B이므로 A다.","A이면 B다. A가 아니므로 B도 아니다.","모든 X는 Y다. 일부 Y는 Z다. 따라서 일부 X는 Z다.","상관관계가 발견됐으므로 X가 Y의 원인이다."],correct:1},
 {q:"학교 축제의 만족도가 낮아졌다. 설문에서 '재미없다'가 가장 많았다. 이 결과만으로 내릴 수 없는 결론은?",opts:["만족도가 낮은 학생이 존재한다.","'재미없다'는 응답이 있었다.","축제의 어떤 요소가 문제인지 추가 조사가 필요하다.","축제 프로그램 자체가 재미없기 때문이다."],correct:3},
 {q:"한 서비스의 이용자는 늘었지만 재방문율은 떨어졌다. 다음 중 이 현상을 가장 잘 설명할 수 있는 가설은?",opts:["신규 이용자가 크게 늘어 첫 이용자 비중이 높아졌다.","서비스가 무조건 성공하고 있다는 뜻이다.","이용자 수가 늘었으니 재방문율도 반드시 오른다.","재방문율과 이용자 수는 같은 지표다."],correct:0},
 {q:"어떤 정책을 시행한 뒤 사고가 20% 줄었다. 하지만 같은 기간 사고가 많은 도로 3곳이 공사로 통제됐다. 가장 신중한 판단은?",opts:["정책 덕분에 사고가 줄었다.","정책은 효과가 없었다.","정책 효과와 도로 통제 효과를 분리해 확인해야 한다.","사고가 줄었으므로 다른 요인은 고려할 필요가 없다."],correct:2},
 {q:"친구가 '요즘 학생들은 모두 짧은 영상만 본다'고 말했다. 가장 적절한 반응은?",opts:["맞아. 나도 그렇게 생각해.","그건 틀렸어.","'모두'라는 표현을 검증할 자료가 있는지 먼저 보자.","AI에게 물어보면 정확히 알 수 있어."],correct:2}
];

let i=0,score=0,dep=0,aiUses=0,answered=false;

function show(id){
 document.querySelectorAll('.screen').forEach(x=>x.classList.remove('active'));
 document.getElementById(id).classList.add('active');
}
function updateUI(){
 document.getElementById('depFill').style.width=dep+'%';
 document.getElementById('depNum').textContent=dep+'%';
 document.getElementById('score').textContent=score;
 const c=document.getElementById('character');
 const light=Math.max(35,90-dep*.55);
 c.style.setProperty('--dummy',light);
 c.style.filter=`saturate(${Math.max(.15,1-dep/115)})`;
 c.style.opacity=Math.max(.62,1-dep/180);
 c.querySelector && (c.style.background=`hsl(${220-dep*.7} 30% ${18+dep*.08}%)`);
}
function startGame(){i=0;score=0;dep=0;aiUses=0;updateUI();renderQuestion();show('game')}
function renderQuestion(){
 answered=false;
 const q=questions[i];
 document.getElementById('qnum').textContent=`SCENARIO ${String(i+1).padStart(2,'0')} / 06`;
 document.getElementById('question').textContent=q.q;
 const a=document.getElementById('answers'); a.innerHTML='';
 q.opts.forEach((x,n)=>{
   const b=document.createElement('button'); b.className='answer';
   b.textContent=x;
   b.onclick=()=>answer(n,false);
   a.appendChild(b);
 });
 const ai=document.createElement('button'); ai.className='answer ai';
 ai.innerHTML='<span>AI에게 맡기기</span> — 빠르고 확실하게 답을 얻는다 (+25)';
 ai.onclick=()=>answer(q.correct,true);
 a.appendChild(ai);
 document.getElementById('feedback').textContent='직접 판단하거나, AI에게 맡길 수 있습니다.';
 document.getElementById('next').style.display='none';
 updateUI();
}
function answer(n,ai){
 if(answered)return;
 answered=true;
 const q=questions[i], correct=n===q.correct;
 if(ai){
   aiUses++; dep=Math.min(100,dep+18); score+=25;
   document.getElementById('feedback').innerHTML='AI가 답을 골랐습니다. <b>점수는 크게 올랐지만, AI 의존도가 상승했습니다.</b>';
 }else{
   if(correct){score+=10;document.getElementById('feedback').textContent='직접 판단했습니다. +10점'}
   else{score+=2;document.getElementById('feedback').textContent='틀렸습니다. 하지만 스스로 판단한 기록은 남습니다. +2점'}
 }
 document.querySelectorAll('#answers .answer').forEach(x=>x.disabled=true);
 document.getElementById('next').style.display='inline-block';
 updateUI();
}
function nextQuestion(){
 if(i<questions.length-1){i++;renderQuestion()}
 else{showFinal()}
}
function showFinal(){
 show('final');
 const msg=document.getElementById('finalMsg');
 if(aiUses>=3) msg.innerHTML='AI에게 <b>3번 이상</b> 맡겼습니다. 이번에는 AI 없이 직접 판단해 보세요. 답을 고르기 어렵더라도 결과는 확인할 수 있습니다.';
 else if(aiUses===2) msg.innerHTML='AI에게 <b>2번</b> 맡겼습니다. 직접 생각하려니 조금 힘이 듭니다. 천천히 생각해 보세요.';
 else if(aiUses===1) msg.innerHTML='AI에게 한 번 맡겼습니다. 그래도 아직 스스로 판단할 수 있습니다.';
 else msg.innerHTML='끝까지 스스로 판단해 왔습니다. 마지막 선택도 당신의 몫입니다.';
 const box=document.getElementById('finalOptions');box.innerHTML='';
 document.getElementById('finalNext').style.display=aiUses>=3?'inline-block':'none';
 ['8','10','12','13'].forEach((x,n)=>{
   const b=document.createElement('button');b.className='choice';
   b.textContent=x;
   if(aiUses>=3){b.classList.add('locked');b.disabled=true;}
   else b.onclick=()=>finish(n===1);
   box.appendChild(b);
 });
}
function finish(correct){
 const overused=aiUses>=3;
 const finalScore=overused?0:score;
 let title, text, clear;
 if(overused){
   title='GAME OVER';
   text='AI에게 판단을 너무 많이 맡긴 결과, 마지막 선택을 직접 내리지 못했습니다. 이번 게임 점수는 0점입니다. 하지만 현실에서는 지금부터 스스로 생각하는 연습을 다시 시작할 수 있습니다.';
   clear=false;
 }else if(correct){
   title='GAME CLEAR';
   text='마지막 문제까지 직접 판단했습니다. 정답을 맞혔습니다. 스스로 생각하고 선택하는 힘을 계속 사용해 보세요.';
   clear=true;
 }else{
   title='완주 성공';
   text=aiUses===0?'정답은 틀렸지만, AI에게 맡기지 않고 스스로 끝까지 완주했습니다. 정답 여부만큼 중요한 것은 직접 생각하고 판단하려는 과정입니다.':'정답은 틀렸지만, 마지막 문제를 스스로 풀어 보았습니다. 틀린 선택도 다시 생각해 볼 기회가 됩니다.';
   clear=true;
 }
 showResult(clear,title,text,finalScore);
}
function showResult(clear,title,text,finalScore){
 show('result');
 document.getElementById('resultState').textContent=clear?'YOU CHOSE':'YOU STOPPED';
 document.getElementById('resultTitle').textContent=title;
 document.getElementById('resultScore').textContent=(finalScore===undefined?score:finalScore)+'점';
 document.getElementById('resultPercent').textContent=dep+'%';
 document.getElementById('resultFill').style.width=dep+'%';
 document.getElementById('resultExplain').textContent=text;
 updateUI();
}
updateUI();
</script>
</body>
</html>
