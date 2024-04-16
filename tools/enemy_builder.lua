local Market = {}

function Market:new(definition)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    self.balance = definition.balance or 0
    self.loaning = definition.loaning or 0
    self.loaning_interest = definition.loaning_interest or 0
    self.loaned_out = definition.loaned_out or 0
    self.loaned_out_interest = definition.loaned_out_interest or 0
    self.invoices = {}
    self.player = definition.player
    return obj
end

function Market:deposit(amount)
    self.balance = self.balance + amount
end

function Market:withdraw(amount)
    local amount = amount
    if self.balance >= amount then
        self.balance = self.balance - amount
        return amount
    elseif self.balance > 0 then
        amount = self.balance/10
        self.balance = self.balance - amount
        return amount
    else
        return false
    end
end

function Market:transfer(data)
    local cost = self:withdraw(data.amount)
    if cost then
        global.markets[data.player].market:deposit(cost)
        return cost
    else
        return 0
    end
end

function Market:give_loan(definition)
    if not definition.player then return end
    local loanee = definition.player
    if not global.markets[loanee] then return end
    self:withdraw(definition.amount)
    local m = global.markets[loanee]
    local total_interest = definition.total_interest or (((definition.percent_interest or 0)/100)*definition.amount)
    m:get_loan{amount = definition.amount, interest = total_interest, player = self.player}
    self.loaned_out = self.loaned_out + definition.amount
    self.loaned_out_interest = self.loaned_out_interest + total_interest
end

function Market:get_loan(definition)
    self.deposit(definition.amount)
    self.loaning = self.loaning + definition.amount
    self.loaning_interest = self.loaning_interest + definition.interest
    table.insert(self.invoices, {player = definition.player, amount = (self.loaning +
    self.loaning_interest))
end

local function on_player_created(event)
    -- teleport player to surface at 0, 0
    local player = game.players[event.player_index]
    global.markets[player.name] = {}
    global.markets[player.name].market = Market:new(player=game.player.name)
end

local function on_nth_tick()
    for name, data in pairs(global.markets) do
        if global.markets[name].market then
            if global.markets[name].market.loaning then
                local m = global.markets[name].market
                for i, invoice in pairs(m.invoices) do
                    local transferred = m.transfer{player=invoice.player, amount = invoice.amount}
                    invoice.amount = invoice.amount - transferred
                end
            end
        end
    end
end

Market.events =
{
    [60*60*5] = on_nth_tick,
    [defines.events.on_player_created] = on_player_created
}

commands.add_command('makemarket', '', function(command)
    local player = game.players[command.player_index]
    local name = 'Vinnie'
    global.markets[name] = {}
    global.markets[name].market = Market:new(player=name)
end)
commands.add_command('loanmarket', '', function(command)
    local player = game.players[command.player_index]
    local name = 'Vinnie'
    local amount = command.parameter
    local market = global.markets[player.name].market
    market:give_loan(player=name, amount=amount, percent_interest=20)

end)
commands.add_command('makemarket', '', function(command)
    local player = game.players[command.player_index]
    local name = command.parameter
    global.markets[name] = {}
    global.markets[name].market = Market:new(player=name)
    Market:new
end)

return Market