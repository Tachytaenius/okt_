local solveQuarticNewton do
	local evaluateQuartic, evaluateQuarticDerivative

	function solveQuarticNewton(guess, iterations, a,b,c,d,e)
		for _=0, iterations do
			guess = evaluateQuartic(guess, a,b,c,d,e) / evaluateQuarticDerivative(guess, a,b,c,d,e)
		end
		return guess
	end

	function evaluateQuartic(t, a,b,c,d,e)
		-- at^4 + bt^3 + ct^2 + dt^1 + et^0
		return a*t*t*t*t + b*t*t*t + c*t*t + d*t + e
	end

	function evaluateQuarticDerivative(t, a,b,c,d,e)
		return 4*a*t*t*t + 3*b*t*t + 2*c*t + d
	end
end


