import { Contract } from "hardhat/internal/hardhat-network/stack-traces/model";
import { loadFixture, ethers, expect } from "./setup";
// мы исопльзуем ts вместо js потому что ts язые со статической типизацией и у нас здесь есть явный автокоплит - удобно!
describe("Demo", function() {
  async function deploy() {
    const [user1, user2] = await ethers.getSigners(); // берем первые два аккаунта из списка 20, которые нам доступны

    const Factory = await ethers.getContractFactory("Demo"); // получаем контракт вводим именно его имя
    const payments = await Factory.deploy(); // деплоим его и через переменную "payments" можно обращаться ко всем методам контракта
    await payments.waitForDeployment(); // дожидаемся пока полностю развернется контракт

    return { user1, user2, payments }
  }


  // пишут строкой, что должен выполнять тест -> должен задеплоиным быть
  it("should be deployed", async function() { // что такое асинхронная ф-я?
    const { payments } = await loadFixture(deploy); // loadFixture - помогает нам тестировать независимо тесты:
    // те мы хотим каждый тест запускать на чистом разеврнутом блоке, тогда loadFixture делает снимок начального deploy
    // и в каждом новом тесте после первого обращается к снимку, поэтом работает быстрее чем каждый раз деплоить по новой

    expect(payments.target).to.be.properAddress;
  });

  it("shound allow to send money", async function() {
    const { user2, payments } = await loadFixture(deploy);
    const amount = 100; // Convert to Wei
  
    const tx = await user2.sendTransaction({
      to: payments.target,
      value: amount
    });

    await tx.wait();
    expect(tx).to.changeEtherBalance(user2, -amount);
    const balance = await ethers.provider.getBalance(payments.target); // баланс контракта должен равнятся 0 - это логично ведь мы его только создали
    expect(balance).to.eq(amount);
  })


  it("shound allow owner to withdraw funds", async function() {
    const { user1, user2, payments } = await loadFixture(deploy);
    const amount = 100; // Convert to Wei
  
    const txSendMoney = await user2.sendTransaction({
      to: payments.target,
      value: amount
    });

    const txWithdrawMoney = await payments.withdraw(user1.address)

    expect(txWithdrawMoney).to.changeEtherBalance([payments, user1], [-amount, amount]);
  })

  it("shound not allow other accounts to withdraw funds", async function() {
    const { user1, user2, payments } = await loadFixture(deploy);
    const amount = 100; // Convert to Wei
  
    const txSendMoney = await user2.sendTransaction({
      to: payments.target,
      value: amount
    });

    await expect(payments.connect(user2).withdraw(user2.address)).to.be.revertedWith("you are not an owner!");
  })
});