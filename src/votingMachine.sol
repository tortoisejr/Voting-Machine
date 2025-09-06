// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract booth {
    struct candidate {
        string name;
        uint candidateId;
        uint voteCount;
    }

    struct Election{
        uint electionId;
        bool isActive;
        string name;
        uint endTime;
        uint candidateCount;
        uint totalVote;
        mapping(address=>bool) hasVoted; 
        mapping (uint => candidate) candidates;
    }

    address public admin;
    uint public electionCount;
    mapping(uint => Election) public  elections;

    event ElectionCreated(uint indexed ElectionId, string ElectionName, uint EndTime);
    event CandidateAdded(uint indexed ElectionId, uint indexed CandidateId, string CandidateName);
    event VoteCast(uint indexed ElectionId, uint indexed CandidateId);
    event ElectionEnded(uint ElectionId, string ElectionName, uint WinnerId, string WinnerName, uint WinnerVotes, uint TotalVote );

    modifier onlyAdmin()
    {
        require(admin== msg.sender,"Only admin can perform this function");
        _;
    }

    modifier electionExists (uint _electionId)
    {
        require( 0 < _electionId && _electionId <= electionCount ,"Election is not Exist");
        _;
    }

    modifier electionActive (uint _electionId)
    {
        require(elections[_electionId].isActive==true && elections[_electionId].endTime>=block.timestamp,"Election is not Active od timeout");
        _;
    }

    modifier candidateValidation(uint _electionId, uint _candidateId)
    {
        require (_candidateId>0 && _candidateId <= elections[_electionId].candidateCount,"Candidate Id is invalid");
        _;
    }

    modifier voteStatus(uint _electionId)
    {
        require(!elections[_electionId].hasVoted[msg.sender],"This voter already give his vote");
        _;
    }

    constructor(){
        admin= msg.sender;
    }

    function CreateElection(string memory _name, uint _duration) public onlyAdmin 
    {
        electionCount++;
        Election storage election = elections[electionCount];
        election.name= _name;
        election.electionId = electionCount;
        election.isActive = true;
        election.endTime = block.timestamp + _duration;
        election.candidateCount=0;  
        election.totalVote;
        emit ElectionCreated(election.electionId, election.name, election.endTime);
    }

    
    function AddCandidate(uint _electionId, string memory  _name) public onlyAdmin electionExists(_electionId) electionActive(_electionId)
    {
        Election storage election = elections[_electionId];
        uint _candidateId =++election.candidateCount;

        election.candidates[_candidateId].candidateId =_candidateId;
        election.candidates[_candidateId].name=_name;
        election.candidates[_candidateId].voteCount=0;
        emit CandidateAdded(election.electionId, election.candidates[_candidateId].candidateId, election.candidates[_candidateId].name);
    }

    function votting(uint _electionId, uint _candidateId) public electionExists(_electionId) electionActive(_electionId) candidateValidation(_electionId,_candidateId) voteStatus(_electionId) {
        elections[_electionId].hasVoted[msg.sender]=true;
        elections[_electionId].candidates[_candidateId].voteCount++;
        elections[_electionId].totalVote++;

        emit VoteCast(elections[_electionId].electionId, elections[_electionId].candidates[_candidateId].candidateId);
    }

    function endElection(uint _electionId) public onlyAdmin electionExists(_electionId) electionActive(_electionId) returns(uint,string memory,uint)
    {
        Election storage election = elections[_electionId];
        election.isActive = false;

        uint winnerId=0;
        string memory winnerName;
        uint winnerVotes=0;

        for(uint i=1; i<= election.candidateCount; i++)
        {
            if(election.candidates[i].voteCount > winnerVotes)
            {
                winnerId = election.candidates[i].candidateId;
                winnerName = election.candidates[i].name;
                winnerVotes = election.candidates[i].voteCount;
            }
        }

        emit ElectionEnded(election.electionId, election.name, winnerId, winnerName, winnerVotes, election.totalVote);
        return (winnerId,winnerName,winnerVotes);

    }

    function getCandidate(uint _electionId, uint _candidateId) public view electionExists(_electionId) candidateValidation(_electionId,_candidateId) returns(uint CandidateId, string memory Name,uint Votes)
    {
        return(elections[_electionId].candidates[_candidateId].candidateId,elections[_electionId].candidates[_candidateId].name,elections[_electionId].candidates[_candidateId].voteCount);
    }

    function getTotalVotes(uint _electionId) public view electionExists(_electionId) returns(string memory Name,uint TotalVotes)
    {
        Election storage election = elections[_electionId];

        return(election.name,election.totalVote);
    }

    function getWinner(uint _electionId) public view electionExists(_electionId) returns(uint WinnerID, string memory WminnerName , uint VoteCount)
    {
         Election storage election = elections[_electionId];

        uint winnerId=0;
        string memory winnerName;
        uint winnerVotes=0;

        for(uint i=1; i<= election.candidateCount; i++)
        {
            if(election.candidates[i].voteCount > winnerVotes)
            {
                winnerId = election.candidates[i].candidateId;
                winnerName = election.candidates[i].name;
                winnerVotes = election.candidates[i].voteCount;
            }
        }
        return (winnerId,winnerName,winnerVotes);
    }
    function getElections() public  view returns(uint [] memory, string [] memory)
    {
        require(electionCount>0,"There is no election is running now");
        uint [] memory electionId= new uint[](electionCount);
        string [] memory Name= new string[](electionCount);
        for(uint i=0;i<electionCount;i++)
        {
            electionId[i] =i+1;
            Name[i]= elections[i+1].name;
        }
        return (electionId,Name);
    }

    function getCandidates(uint _electionId) public view electionExists(_electionId) returns(uint [] memory, string [] memory)
    {
        require(elections[_electionId].candidateCount>0,"There is no candidates for this election");
        uint [] memory candidateId= new uint[](elections[_electionId].candidateCount);
        string [] memory Name= new string [](elections[_electionId].candidateCount);
        for(uint i=0;i<elections[_electionId].candidateCount;i++)
        {
            candidateId[i] =i+1;
            Name[i]= elections[_electionId].candidates[i+1].name;
        }
        return (candidateId,Name);
    }

}