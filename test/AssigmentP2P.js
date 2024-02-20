const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("AssigmentP2P", function() {
  let AssigmentP2P;
  let assigmentP2P;
  let owner;
  let borrower;
  let guarantor;
  let lender;
  let addrs;

  beforeEach(async function () {
    AssigmentP2P = await ethers.getContractFactory("AssigmentP2P");
    [owner, borrower, guarantor, lender, ...addrs] = await ethers.getSigners();

    assigmentP2P = await AssigmentP2P.deploy();
    await assigmentP2P.waitForDeployment();
  });

  describe("Loan creation", function () {
    it("Should create a new loan and emit an event", async function () {
      const dueDate = 1659322222;
      const amount = 1000;
      const interest = 5;
      const tx = await assigmentP2P.connect(borrower).createNewLoan(dueDate, amount, interest);
      await expect(tx).to.emit(assigmentP2P, "LoanCreated").withArgs(0);
      const loan = await assigmentP2P.loans(0);
      expect(loan.dueDate).to.equal(dueDate);
      expect(loan.amount).to.equal(amount);
      expect(loan.interest).to.equal(interest);
      expect(loan.borrower).to.equal(borrower.address);
    });
  });

  describe("Offer Guarantee", function () {
    it("Allow a guarantor to offer a guarantee", async function () {
      const dueDate = 1659322222;
      const loanAmount = 1000;
      const interest = 5;
      await assigmentP2P.connect(borrower).createNewLoan(dueDate, loanAmount, interest);
  
      const guaranteeInterest = 3;
      const guaranteeAmount = loanAmount + interest - guaranteeInterest;
      const loanId = 0;
  
      const offerGuaranteeTx = await assigmentP2P.connect(guarantor).offerGuarantee(loanId, guaranteeInterest, { value: guaranteeAmount });
      await expect(offerGuaranteeTx).to.emit(assigmentP2P, "GuaranteeOffered").withArgs(loanId, guarantor.address);
  
      const loan = await assigmentP2P.loans(loanId);
      expect(loan.guarantor).to.equal(guarantor.address);
      expect(loan.guarantorInterest).to.equal(guaranteeInterest);
    });
  });

  describe("Offer Guarantee", function () {
    it("Incorrect guarantee amount", async function () {
      const dueDate = 1659322222;
      const loanAmount = 1000;
      const interest = 5;
      await assigmentP2P.connect(borrower).createNewLoan(dueDate, loanAmount, interest);
  
      const guaranteeInterest = 3;
      const incorrectGuaranteeAmount = 0;
      const loanId = 0; 
  
      await expect(
        assigmentP2P.connect(guarantor).offerGuarantee(loanId, guaranteeInterest, { value: incorrectGuaranteeAmount })
      ).to.be.revertedWith("Incorrect guarantee amount");
    });
  });

  describe("Deny Guarantee", function () {
    it("Deny guarantee", async function () {
      const dueDate = 1659322222;
      const loanAmount = 10;
      const interest = 5;
      await assigmentP2P.connect(borrower).createNewLoan(dueDate, loanAmount, interest);
  
      const guaranteeInterest = 3;
      const guaranteeAmount = loanAmount + interest - guaranteeInterest;
      const loanId = 0;
      await assigmentP2P.connect(guarantor).offerGuarantee(loanId, guaranteeInterest, { value: guaranteeAmount });
  
      const denyGuaranteeTx = assigmentP2P.connect(borrower).denyGuarantee(loanId);
      await expect(denyGuaranteeTx).to.emit(assigmentP2P, "GuaranteeDenied").withArgs(loanId);
  
      const loan = await assigmentP2P.loans(loanId);
      expect(loan.guarantorInterest).to.equal(0);
    });
  });
});
