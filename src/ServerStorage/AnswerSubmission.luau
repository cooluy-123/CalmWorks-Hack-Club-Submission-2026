local HttpService = game:GetService("HttpService")
local Submission = {}

function Submission.Token(data)
    if not data.AnswerToken or data.AnswerStage ~= data.StageIndex then
        data.AnswerToken = HttpService:GenerateGUID(false)
        data.AnswerStage = data.StageIndex
    end
    return data.AnswerToken
end

function Submission.Check(data, token, answer)
    if type(token) ~= "string" or #token > 80 then
        return "Expired"
    end
    local previous = data.LastSubmission
    if previous and previous.Token == token and previous.Answer == answer then
        if previous.Result then
            return "Repeat", previous.Result
        end
        return "Busy"
    end
    if data.AnswerStage ~= data.StageIndex or data.AnswerToken ~= token then
        return "Expired"
    end
    return "Ready"
end

function Submission.Begin(data, token, answer)
    data.LastSubmission = { Token = token, Answer = answer }
    data.AnswerToken = HttpService:GenerateGUID(false)
    data.AnswerStage = data.StageIndex
end

function Submission.Finish(data, result)
    result.AnswerToken = Submission.Token(data)
    data.LastSubmission.Result = result
    return result
end

return Submission
