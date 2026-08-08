import './style.css';

const state = {
  profile: null,
  payment: null,
  rewards: null,
};

const bridge = {
  async call(action, payload = {}) {
    if (window.SuperAppBridge?.call) {
      return window.SuperAppBridge.call(action, payload);
    }

    return {
      ok: true,
      data: mockResponse(action, payload),
    };
  },
};

function mockResponse(action, payload) {
  switch (action) {
    case 'getUserProfile':
      return {
        id: 'MH-1001',
        name: 'Aung Myat',
        tier: 'Verified',
        phone: '+95 9 987 654 321',
      };
    case 'requestPayment':
      return {
        transactionId: `MH-PAY-${Date.now()}`,
        amount: payload.amount,
        currency: 'MMK',
        status: 'Paid',
      };
    case 'getRewards':
      return {
        points: 2450,
        level: 'Silver',
        nextReward: '500 MMK cashback',
      };
    case 'closeMiniApp':
      return { closed: true };
    default:
      return { received: payload };
  }
}

document.querySelector('#app').innerHTML = `
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
`;

document.querySelector('.phone').addEventListener('click', async (event) => {
  const button = event.target.closest('button[data-action]');
  if (!button) return;

  button.disabled = true;
  const original = button.textContent;
  if (button.classList.contains('pay-btn')) {
    button.textContent = 'Processing...';
  }

  try {
    await handleAction(button.dataset.action);
  } finally {
    button.disabled = false;
    if (button.classList.contains('pay-btn')) {
      button.textContent = original;
    }
  }
});

async function handleAction(action) {
  if (action === 'profile') {
    const response = await bridge.call('getUserProfile');
    state.profile = response.data;
    document.querySelector('#profile').textContent =
      `${state.profile.name} · ${state.profile.tier}`;
  }

  if (action === 'payment') {
    const response = await bridge.call('requestPayment', {
      amount: 12500,
      currency: 'MMK',
      orderId: 'MH-QUICKPAY-001',
    });
    state.payment = response.data;
    document.querySelector('#payment').textContent =
      `${state.payment.status} · ${state.payment.transactionId.slice(-6)}`;
    await handleAction('rewards');
  }

  if (action === 'rewards') {
    const response = await bridge.call('getRewards', {
      userId: state.profile?.id ?? 'anonymous',
    });
    state.rewards = response.data;
    document.querySelector('#rewards').textContent =
      `${state.rewards.points} pts · ${state.rewards.nextReward}`;
  }

  if (action === 'close') {
    await bridge.call('closeMiniApp');
  }
}
