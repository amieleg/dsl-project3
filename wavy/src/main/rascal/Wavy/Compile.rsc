module Wavy::Compile

import Wavy::Syntax;
import Wavy::AST;

import IO;
import util::Math;
import List;
import util::Maybe;
import Map;

map[str, num] VARTABLE = ();
map[str, tuple[list[str] parameters, list[StatementAST] body]] FUNCTABLE = (("Sine": <["t", "freq"], []>));
ExpressionAST output_statement;

Maybe[StatementAST] find_output(WavyAST ast) {
  for (StatementAST stat <- ast.program) {
    if (\output(_, _) := stat) {
      return just(stat);
    }
  }

  return nothing();
}

// args denotes the given parameters
Maybe[num] eval_func(list[StatementAST] sn, map[str, num] args)
{
  for(StatementAST s <- sn)
  {
    //println(s);
    switch (s)
    {
      case \expression(ExpressionAST expr):
      {
        return just(eval_expression(expr, args));
      }
      case \functionDeclaration(str id, list[str] parameters, list[StatementAST] body):
      {
        FUNCTABLE += (id: <parameters, body>);
      }
      case \output(ExpressionAST result, num duration):
      {
        output_statement = result;
        return just(eval_expression(result, args));
      }
      case \if(ExpressionAST condition, list[StatementAST] body):
      {
        if (eval_expression(condition, args) == 1)
        {
          result = eval_func(body, args);
          if (result != nothing())
          {
            return result;
          }
        }
      }
      case \ifelse(ExpressionAST condition, list[StatementAST] true_body, list[StatementAST] false_body):
      {
        if (eval_expression(condition, args) == 1)
        {
          result = eval_func(true_body, args);
          if (result != nothing())
          {
            return result;
          }
        }
        else
        {
          result = eval_func(false_body, args);
          if (result != nothing())
          {
            return result;
          }
        }
      }
      case \while(ExpressionAST condition, list[StatementAST] body):
      {
        while (eval_expression(condition, args) == 1)
        {
          result = eval_func(body, args);
          if (result != nothing())
          {
            return result;
          }
        }
      }
      case \declaration(str id, ExpressionAST expr):
      {
        VARTABLE += (id: eval_expression(expr, args));
      }
    }
  }
  return nothing();
}

// evaluate a list of arguments and match the values with their names
map[str, num] instantiate_args(list[str] parameters, list[ExpressionAST] arguments, map[str, num] args)
{
  list[num] evaluated_arguments = [];
  
  for (ExpressionAST e <- arguments)
  {
    evaluated_arguments += eval_expression(e, args);
  }

  map[str, num] outmap = ();
  for (int i <- [0..size(parameters)])
  {
    outmap += (parameters[i]: evaluated_arguments[i]);
  }
  return outmap;
}

real sine(real t, real freq)
{
  return sin(2 * PI() * freq * t);
}

num eval_expression(ExpressionAST e, map[str, num] args)
{
  switch (e)
  {
    // math
    case \addition(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) + eval_expression(rhs, args);
    }
    case \subtraction(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) - eval_expression(rhs, args);
    }
    case \multiplication(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) * eval_expression(rhs, args);
    }
    case \division(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) / eval_expression(rhs, args);
    }
    case \power(ExpressionAST lhs, ExpressionAST rhs):
    {
        return pow(eval_expression(lhs, args), toReal(eval_expression(rhs, args)));
    }

    // comparison
    case \less(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) < eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \lesseq(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) <= eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \greater(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) > eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \greatereq(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) >= eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \equal(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) == eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    
    // simple
    case \brackets(ExpressionAST expr):
    {
      return eval_expression(expr,args);
    }
    case \number(num val):
    {
      return val;
    }

    // complex
    case \var(str id):
    {
      if (id in args)
      {
        return args[id];
      }
      return VARTABLE[id];
    }
    case \call(str func, list[ExpressionAST] arguments):
    {
      func_info = FUNCTABLE[func];
      call_args = instantiate_args(func_info[0], arguments, args);

      if (func == "Sine")
      {
        return sine(toReal(call_args["t"]), toReal(call_args["freq"]));
      }

      result = eval_func(func_info[1], call_args);

      switch (result)
      {
        case just(val):
        {
          return val;
        }
      }
    }
  }
  return -1;
}

list[int] num_to_4_bytes(int n)
{
  int first = n % 256;
  int second = n / 256;
  int third = n / (256*256);
  int fourth = n / (256*256*256);

  return [first, second, third, fourth];
}

list[int] num_to_2_bytes(int n)
{
  int small = n % 256;
  int big = (n-small)/256;
  return [small, big];
}

list[int] get_header(int length)
{
  wav_header = [82, 73, 70, 70] + num_to_4_bytes(36 + (length * 4)) + [87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 2, 0] + num_to_4_bytes(RATE) + num_to_4_bytes(length*4) + [4, 0, 16, 0, 100, 97, 116, 97] + num_to_4_bytes(length * 4);
  return wav_header;
}

int float_to_sample(real f)
{
  int i = round(f * 65535);

  return i;
}

// Normalizes to values between -0.5 and 0.5 based on the max of the list
list[real] normalize(list[real] input)
{
  maxval = max(input);

  list[real] outlist = [];

  for (real f <- input)
  {
    outlist += 0.5 * (f / maxval);
  }
  return outlist;
}

int RATE = 4410;

void compile(WavyAST ast)
{
    length = 3.0; 
    ExpressionAST expr;

    if (just(\output(ExpressionAST e, num duration)) := find_output(ast)) {
      length = duration;
      expr = e;
    }

    mayberesult0 = eval_func(ast.program,("t": 0));
    num result0;
    switch(mayberesult0)
    {
      case just(n):
      {
        result0 = n;
      }
    }

    list[num] samples = [result0];
    int n_samples = toInt(length * RATE);

    for (i <- [1..n_samples])
    {
      println(i);
        num t = toReal(i) * (1.0 / RATE);
        result = eval_expression(output_statement, ("t": t));

        samples += result;
    }

    samples = normalize(samples);
    
    wav = get_header(n_samples);

    for(f <- samples)
    {
        as_2_bytes = num_to_2_bytes(float_to_sample(f));
        wav += as_2_bytes;
        wav += as_2_bytes;
    }

    testfile = |project://wavy/tests/out.wav|;
    writeFileBytes(testfile, wav);
}