(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e={profile:null,payment:null,rewards:null},t={async call(e,t={}){return window.SuperAppBridge?.call?window.SuperAppBridge.call(e,t):{ok:!0,data:n(e,t)}}};function n(e,t){switch(e){case`getUserProfile`:return{id:`MH-1001`,name:`Aung Myat`,tier:`Verified`,phone:`+95 9 987 654 321`};case`requestPayment`:return{transactionId:`MH-PAY-${Date.now()}`,amount:t.amount,currency:`MMK`,status:`Paid`};case`getRewards`:return{points:2450,level:`Silver`,nextReward:`500 MMK cashback`};case`closeMiniApp`:return{closed:!0};default:return{received:t}}}document.querySelector(`#app`).innerHTML=`
  <main class="phone">
    <header class="top">
      <button class="icon-btn" data-action="close" aria-label="Close mini app">x</button>
      <div class="brand">
        <span class="logo-mark"><span></span></span>
        <div>
          <strong>QuickPay Pass</strong>
          <small>MiniHub</small>
        </div>
      </div>
      <button class="icon-btn" data-action="rewards" aria-label="Refresh rewards">↻</button>
    </header>

    <section class="wallet">
      <span>Available balance</span>
      <strong>128,000 MMK</strong>
      <p>Ready for quick payment</p>
    </section>

    <section class="merchant">
      <div>
        <span class="merchant-icon">Q</span>
      </div>
      <div>
        <small>Paying to</small>
        <strong>QuickMart Downtown</strong>
        <span>Order #MH-2048</span>
      </div>
    </section>

    <section class="amount-card">
      <span>Total amount</span>
      <strong>12,500 MMK</strong>
      <button data-action="payment" class="pay-btn">Pay Now</button>
    </section>

    <section class="quick-actions">
      <button data-action="profile">
        <span>👤</span>
        Profile
      </button>
      <button data-action="rewards">
        <span>★</span>
        Rewards
      </button>
    </section>

    <section class="receipt" id="receipt">
      <div>
        <span>Status</span>
        <strong id="payment">Waiting for payment</strong>
      </div>
      <div>
        <span>Member</span>
        <strong id="profile">Tap Profile</strong>
      </div>
      <div>
        <span>Rewards</span>
        <strong id="rewards">Tap Rewards</strong>
      </div>
    </section>
  </main>
`,document.querySelector(`.phone`).addEventListener(`click`,async e=>{let t=e.target.closest(`button[data-action]`);if(!t)return;t.disabled=!0;let n=t.textContent;t.classList.contains(`pay-btn`)&&(t.textContent=`Processing...`);try{await r(t.dataset.action)}finally{t.disabled=!1,t.classList.contains(`pay-btn`)&&(t.textContent=n)}});async function r(n){n===`profile`&&(e.profile=(await t.call(`getUserProfile`)).data,document.querySelector(`#profile`).textContent=`${e.profile.name} · ${e.profile.tier}`),n===`payment`&&(e.payment=(await t.call(`requestPayment`,{amount:12500,currency:`MMK`,orderId:`MH-QUICKPAY-001`})).data,document.querySelector(`#payment`).textContent=`${e.payment.status} · ${e.payment.transactionId.slice(-6)}`,await r(`rewards`)),n===`rewards`&&(e.rewards=(await t.call(`getRewards`,{userId:e.profile?.id??`anonymous`})).data,document.querySelector(`#rewards`).textContent=`${e.rewards.points} pts · ${e.rewards.nextReward}`),n===`close`&&await t.call(`closeMiniApp`)}