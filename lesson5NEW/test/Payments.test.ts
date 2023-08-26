import { loadFixture, ethers, expect } from "./setup";
// мы исопльзуем ts вместо js потому что ts язые со статической типизацией и у нас здесь есть явный автокоплит - удобно!
describe("Payments", function() {
  async function deploy() {
    const [user1, user2] = await ethers.getSigners(); // берем первые два аккаунта из списка 20, которые нам доступны

    const Factory = await ethers.getContractFactory("Payments"); // получаем контракт вводим именно его имя
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

  it("should have 0 ethers by default", async function() {
    const { payments } = await loadFixture(deploy);

    // const balance = await payments.currentBalance();
    const balance = await ethers.provider.getBalance(payments.target); // баланс контракта должен равнятся 0 - это логично ведь мы его только создали
    expect(balance).to.eq(0);
  });

  it("should be possible to send funds", async function() {
    const { user1, user2, payments } = await loadFixture(deploy);

    const sum = 100; // wei
    const msg = "hello from hardhat";

    //console.log(await ethers.provider.getBalance(user1.address));
    const tx1 = await payments.connect(user2).pay(msg, { value: sum }); // конектим юзера 2 для совершения транзакции, иначе по дефолту траназакцию совершит юзер1
    const tx2 = await payments.pay(msg, { value: 2 * sum }); 
    //console.log(await ethers.provider.getBalance(user1.address));

    const receipt1 = await tx1.wait(1);
    const receipt2 = await tx2.wait(1);

    const tx1Block = await ethers.provider.getBlock(
      await ethers.provider.getBlockNumber() - 1
    );
    const tx1Block2 = await ethers.provider.getBlock(
        await ethers.provider.getBlockNumber()
    );

    expect(tx1).to.changeEtherBalance(user2, -sum);
    expect(tx2).to.changeEtherBalance(user1, -2 * sum);

    const newPayment1 = await payments.getPayment(user2.address, 0); // когда писать await а когда не писать?
    const newPayment2 = await payments.getPayment(user1.address, 0)

    expect(newPayment1.message).to.eq(msg);
    expect(newPayment1.amount).to.eq(sum);
    expect(newPayment1.from).to.eq(user2.address);
    expect(newPayment1.timestamp).to.eq(tx1Block?.timestamp);

    expect(newPayment2.message).to.eq(msg);
    expect(newPayment2.amount).to.eq(2*sum);
    expect(newPayment2.from).to.eq(user1.address);
    expect(newPayment2.timestamp).to.eq(tx1Block2?.timestamp);
    
    const balance = await ethers.provider.getBalance(payments.target); // баланс контракта должен равнятся 300wei
    expect(balance).to.eq(300);
  });
});