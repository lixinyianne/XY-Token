pragma solidity >0.4.22 <0.6.0;

library SafeCalculate {
    //Adds two numbers, throws on overflow
    function add(uint _x, uint _y) internal pure returns (uint z) {
        z = _x + _y;
        assert(z >= _x);
        return z;
    }
  
    //Subtracts two numbers, throws on overflow
    function sub(uint _x, uint _y) internal pure returns (uint) {
        assert(_x >= _y);
        return _x - _y;
    }
  
    //Multiplies two numbers, throws on overflow
    function mul(uint _x, uint _y) internal pure returns (uint z) {
        z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }

    //Integer division of two numbers, truncating the quotient
    function div(uint _x, uint _y) internal pure returns (uint) {
        return _x / _y;
    }
}

contract ERC20 {
    uint public totalSupply;
    
    function allowance(address _owner, address _spender) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
      
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Mint(uint value);
    event Destroy(uint value);
}

contract Administration {
    address public administrator;
    
    mapping(address => bool) public institutions;
    
    /// @notice Set the original administrator as the contract creator
    constructor() public {
        administrator = msg.sender;
    }
    
    modifier onlyAdministrator {
        require (msg.sender == administrator);
        _;
    }

    modifier validAddress (address _address) {
        require(_address != address(0));
        _;
    }
    
    /// @notice Name institutions out of other customers
    function nameInstitution (address _address) 
        public
        onlyAdministrator 
        validAddress(_address)
        returns (bool success)
    {
        institutions[_address] = true;
        return true;
    }
    
    modifier onlyInstitutions {
        require (institutions[msg.sender] == true);
        _;
    }

    /// @notice Assign a new administrator
    function transferOwnership(address newAdministrator) 
        public
        onlyAdministrator 
        validAddress(newAdministrator)
        returns (bool success)
    {
        administrator = newAdministrator;
        return true;
    }
}

contract StandardToken is ERC20, Administration {
    using SafeCalculate for uint;

    mapping(address => uint) internal balanceOf;
    mapping (address => mapping (address => uint)) internal allowedAmount;
    
    /// @notice Get the balance of the specified account.
    function balances(address _address) public view returns (uint) {
        require(_address == msg.sender);
        return balanceOf[_address] / (10**18);
    }

    /// @notice Check the amount of tokens that a spender is allowed to spend.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    function allowance(address _owner, address _spender) public view returns (uint){
        require(_owner == msg.sender || _spender == msg.sender);
        return allowedAmount[_owner][_spender] / (10**18);
    }

    /// @notice Transfer token for a specified address.
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(address _to, uint _value) 
        public 
        validAddress(_to) 
        returns (bool) 
    {
        //With the SafeCalculate, the balance can only be deducted what it has.
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value * (10**18));
        balanceOf[_to] = balanceOf[_to].add(_value * (10**18));
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /// @notice Set allowance for other addresses
    /// @param _spender The address allowed to spend
    /// @param _value The max amount the spender can spend
    function approve(address _spender, uint _value)
        public 
        onlyInstitutions 
        returns (bool) 
    {
        require (allowedAmount[msg.sender][_spender] == 0);
        allowedAmount[msg.sender][_spender] = _value * (10**18);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    /// @notice Transfer tokens from one address to another.
    /// @param _from The address msg.sender want to send tokens from.
    /// @param _to The address msg.sender want to transfer to.
    /// @param _value The amount of tokens to be transferred.
    function transferFrom(address _from, address _to, uint _value) 
        public 
        validAddress(_from) validAddress(_to) onlyInstitutions 
        returns (bool)
    {
        //With the SafeCalculate, the allowance can only be deducted what it has.
        allowedAmount[msg.sender][_from] = allowedAmount[msg.sender][_from].sub(_value * (10**18));
        balanceOf[_from] = balanceOf[_from].sub(_value * (10**18));
        balanceOf[_to] = balanceOf[_to].add(_value * (10**18));
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Increase the amount of tokens that an owner allowed to a spender.
    /// @param _spender The address which will spend the funds.
    /// @param _addedValue The amount of tokens added to the allowance.
    function increaseApproval(address _spender, uint _addedValue)
        public 
        onlyInstitutions 
        returns (bool) 
    {
        allowedAmount[msg.sender][_spender] = (allowedAmount[msg.sender][_spender].add(_addedValue * (10**18)));
        emit Approval(msg.sender, _spender, allowedAmount[msg.sender][_spender]);
        return true;
    }

    /// @notice Decrease the amount of tokens that an owner allowed to a spender.
    /// @param _spender The address which will spend the funds.
    /// @param _subtractedValue The amount of tokens decreased to the allowance.
    function decreaseApproval(address _spender,  uint _subtractedValue) 
        public 
        onlyInstitutions 
        returns (bool) 
    {
        //With the SafeCalculate, the spender can only be deducted what it has.
        allowedAmount[msg.sender][_spender] = (allowedAmount[msg.sender][_spender].sub(_subtractedValue * (10**18)));
        emit Approval(msg.sender, _spender, allowedAmount[msg.sender][_spender]);
        return true;
    }
    
    /// @notice Mint tokens, adding ‘_value’ tokens to system
    /// @param _value the amount of money to add
    function mint(uint _value) 
        public 
        onlyAdministrator 
        returns (bool success) 
    {
        totalSupply = totalSupply.add(_value * (10**18));
        emit Mint(_value);
        return true;
    }
    
    /// @notice Destroy tokens, removing '_value' tokens from  system irreversibly
    /// @param _value the amount of money to burn
    function destory(uint _value) public onlyAdministrator returns (bool success) {
        totalSupply = totalSupply.sub(_value * (10**18));
        emit Destroy(_value);
        return true;
    }
}

contract XYtoken is StandardToken {
    /// @notice Public variables of the token
    string public name = "XY Token";
    string public symbol = "XY";
    uint8 constant public decimals = 18;    //an officially suggested default value
    uint constant public initialSupply = 1000000000;

    constructor() public {
        totalSupply = initialSupply * 10 ** uint(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
}