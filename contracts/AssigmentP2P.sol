// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract AssigmentP2P {
  struct Loan {
      uint256 id;
      uint256 dueDate;
      address borrower;
      uint256 amount;
      uint256 interest;
      uint256 alreadyPaid;
      address guarantor;
      uint256 guarantorInterest;
      bool guarantorAccepted;
      address lender;
  }

  Loan[] public loans;
  uint256 public loanCounter;

  event LoanCreated(uint256 loanId);
  event GuaranteeOffered(uint256 loanId, address guarantor);
  event GuaranteeDenied(uint256 loanId);
  event GuaranteeAccepted(uint256 loanId);
  event LoanPaid(uint256 loanId, uint256 amount);
  event CollateralClaimed(uint256 loanId);
  event LoanStarted(uint256 loanId, address lender);

  function createNewLoan(uint256 _dueDate, uint256 _amount, uint256 _interest) public {
      Loan memory newLoan = Loan({
          id: loanCounter,
          dueDate: _dueDate,
          borrower: msg.sender,
          amount: _amount,
          interest: _interest,
          alreadyPaid: 0,
          guarantor: address(0),
          guarantorInterest: 0,
          guarantorAccepted: false,
          lender: address(0)
      });

      loans.push(newLoan);
      loanCounter++;

      emit LoanCreated(newLoan.id);
  }

  function offerGuarantee(uint256 loanId, uint256 guaranteeInterest) public payable {
      require(loanId < loans.length, "Invalid loan ID");
      Loan storage loan = loans[loanId];

      require(loan.guarantor == address(0), "Guarantor already set");
      require(!loan.guarantorAccepted, "Guarantee already accepted");
      require(guaranteeInterest < loan.interest, "Guarantee interest too high");
      require(msg.value == loan.amount + loan.interest - guaranteeInterest, "Incorrect guarantee amount");

      loan.guarantor = msg.sender;
      loan.guarantorInterest = guaranteeInterest;

      emit GuaranteeOffered(loanId, msg.sender);
  }

  function acceptGuarantee(uint256 loanId) public {
      require(loanId < loans.length, "Invalid loan ID");
      Loan storage loan = loans[loanId];

      require(msg.sender == loan.borrower, "Only borrower can accept");
      require(loan.guarantor != address(0), "Guarantor not set");
      require(!loan.guarantorAccepted, "Guarantee already accepted");

      loan.guarantorAccepted = true;

      emit GuaranteeAccepted(loanId);
  }

  function denyGuarantee(uint256 loanId) public {
      require(loanId < loans.length, "Invalid loan ID");
      Loan storage loan = loans[loanId];

      require(msg.sender == loan.borrower, "Only the borrower can deny the guarantee");
      require(loan.guarantor != address(0), "No guarantor set");
      require(!loan.guarantorAccepted, "Guarantee already accepted");

      payable(loan.guarantor).transfer(loan.amount + loan.interest - loan.guarantorInterest);

      loan.guarantor = address(0);
      loan.guarantorInterest = 0;

      emit GuaranteeDenied(loanId);
  }

  function payLoan(uint256 loanId) public payable {
      require(loanId < loans.length, "Invalid loan ID");
      Loan storage loan = loans[loanId];

      require(msg.sender == loan.borrower, "Only borrower can repay");
      require(loan.lender != address(0), "Loan not started");
      require(msg.value <= loan.amount + loan.interest - loan.alreadyPaid, "Overpayment not allowed");

      uint256 restOfGuarantedAmount = loan.amount + loan.interest - loan.guarantorInterest - loan.alreadyPaid;
      
      uint256 amountToTransferToGuarantor = restOfGuarantedAmount > msg.value ? msg.value : restOfGuarantedAmount;

      loan.alreadyPaid += msg.value;

      payable(loan.lender).transfer(msg.value);

      if (amountToTransferToGuarantor > 0) {
          payable(loan.guarantor).transfer(amountToTransferToGuarantor);
      }

      emit LoanPaid(loanId, msg.value);
  }


  function claimCollateral(uint256 loanId) public {
      require(loanId < loans.length, "Invalid loan ID");
      Loan storage loan = loans[loanId];

      require(msg.sender == loan.lender, "Only lender can claim");
      require(block.timestamp > loan.dueDate, "Loan not yet due");
      require(loan.alreadyPaid < loan.amount + loan.interest, "Loan fully repaid");

      uint256 totalLoanValue = loan.amount + loan.interest;
      uint256 amountDueToLender = totalLoanValue - loan.alreadyPaid;
      uint256 guarantorAmount = 0;

      if (loan.guarantor != address(0) && loan.guarantorInterest > loan.alreadyPaid) {
          uint256 guarantorCoverage = loan.guarantorInterest - loan.alreadyPaid;
          if (guarantorCoverage < amountDueToLender) {
              guarantorAmount = guarantorCoverage;
              amountDueToLender -= guarantorCoverage;
          } else {
              guarantorAmount = amountDueToLender;
              amountDueToLender = 0;
          }
      }

      if (amountDueToLender > 0 && address(this).balance >= amountDueToLender) {
          payable(loan.lender).transfer(amountDueToLender);
      } else if (guarantorAmount > 0 && address(this).balance >= guarantorAmount) {
          payable(loan.guarantor).transfer(guarantorAmount);
      }

      loan.alreadyPaid = totalLoanValue;

      emit CollateralClaimed(loanId);
  }


  function lenderAcceptLoan(uint256 loanId) public payable {
      require(loanId < loans.length, "Invalid loan ID");
      Loan storage loan = loans[loanId];

      require(loan.lender == address(0), "Loan already has lender");
      require(loan.guarantor != address(0), "Guarantee required");
      require(msg.value == loan.amount, "Incorrect amount");

      loan.lender = msg.sender;
      payable(loan.borrower).transfer(msg.value);

      emit LoanStarted(loanId, msg.sender);
  }

  function getAllLoans() public view returns (Loan[] memory) {
      return loans;
  }

  function getBorrowerLoans() public view returns (Loan[] memory) {
      uint count = 0;
      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].borrower == msg.sender) {
              count++;
          }
      }

      Loan[] memory borrowerLoans = new Loan[](count);
      count = 0;

      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].borrower == msg.sender) {
              borrowerLoans[count] = loans[i];
              count++;
          }
      }
      return borrowerLoans;
  }

  function getGuarantorLoans() public view returns (Loan[] memory) {
      uint count = 0;
      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].guarantor == msg.sender) {
              count++;
          }
      }

      Loan[] memory guarantorLoans = new Loan[](count);
      count = 0;

      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].guarantor == msg.sender) {
              guarantorLoans[count] = loans[i];
              count++;
          }
      }
      return guarantorLoans;
  }

  function getLenderLoans() public view returns (Loan[] memory) {
      uint count = 0;
      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].lender == msg.sender) {
              count++;
          }
      }

      Loan[] memory borrowerLoans = new Loan[](count);
      count = 0;

      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].lender == msg.sender) {
              borrowerLoans[count] = loans[i];
              count++;
          }
      }
      return borrowerLoans;
  }

  function getLoansWithoutGuarantee() public view returns (Loan[] memory) {
      uint count = 0;
      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].guarantor == address(0)) {
              count++;
          }
      }

      Loan[] memory noGuaranteeLoans = new Loan[](count);
      count = 0;

      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].guarantor == address(0)) {
              noGuaranteeLoans[count] = loans[i];
              count++;
          }
      }
      return noGuaranteeLoans;
  }

  function getAcceptedGuaranteedLoansWithoutLender() public view returns (Loan[] memory) {
      uint count = 0;
      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].guarantorAccepted && loans[i].lender == address(0)) {
              count++;
          }
      }

      Loan[] memory acceptedLoans = new Loan[](count);
      count = 0;

      for (uint i = 0; i < loans.length; i++) {
          if (loans[i].guarantorAccepted && loans[i].lender == address(0)) {
              acceptedLoans[count] = loans[i];
              count++;
          }
      }
      return acceptedLoans;
  }
}