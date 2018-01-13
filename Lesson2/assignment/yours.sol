pragma solidity ^0.4.14;

contract Payroll {
    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }
    
    uint constant payDuration = 10 seconds;
    uint totalSalary = 0;

    address owner;
    Employee[] employees;

    function Payroll() {
        owner = msg.sender;
    }
    
    function _partialPaid(Employee employee) private {
        uint partialPayment = employee.salary * (now - employee.lastPayday) / payDuration;
        assert(this.balance >= partialPayment);
        
        employee.lastPayday = now;
        employee.id.transfer(partialPayment);
    }
    
    function _findEmployee(address employeeId) private returns (Employee, uint) {
        for (uint i = 0; i < employees.length; i++) {
            if (employees[i].id == employeeId) {
                return (employees[i], i);
            }
        }
    }

    function addEmployee(address employeeId, uint salary) {
        require(msg.sender == owner);
        
        var (employee, _index) = _findEmployee(employeeId);
        assert(employee.id == 0x0);
        
        employees.push(Employee(employeeId, salary, now));
        totalSalary += salary;
    }
    
    function removeEmployee(address employeeId) {
        require(msg.sender == owner);
        
        var (employee, index) = _findEmployee(employeeId);
        assert(employee.id != 0x0);
        
        _partialPaid(employees[index]);
        
        totalSalary -= employees[index].salary;
        delete employees[index];
        employees[index] = employees[employees.length - 1];
        employees.length--;
    }
    
    function updateEmployee(address employeeId, uint salary) {
        require(msg.sender == owner);
        
        var (employee, index) = _findEmployee(employeeId);
        assert(employee.id != 0x0);
        
        _partialPaid(employees[index]);
        
        uint newSalary = salary * 1 ether;
        totalSalary += newSalary - employees[index].salary;
        employees[index].salary = newSalary;
    }
    
    function addFund() payable returns (uint) {
        require(msg.sender == owner);
        
        return this.balance;
    }
    
    /* Optimize this operation by storing a running count of totalSalary
       whenever an employee is added, removed, or updated */
    function calculateRunway() returns (uint) {
        return this.balance / totalSalary;
    }
    
    function hasEnoughFund() returns (bool) {
        return calculateRunway() > 0;
    }
    
    function getPaid() {
        var (employee, index) = _findEmployee(msg.sender);
        assert(employee.id != 0x0);
        
        uint nextPayday = employees[index].lastPayday + payDuration;
        assert(nextPayday >= now);
        assert(this.balance >= employees[index].salary);
        
        employees[index].lastPayday = nextPayday;
        employees[index].id.transfer(employees[index].salary);
    }
}
