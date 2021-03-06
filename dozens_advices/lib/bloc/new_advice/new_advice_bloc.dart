import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dozens_advices/data/database/advice.dart';
import 'package:dozens_advices/data/repository.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../bloc.dart';

class NewAdviceBloc extends Bloc<NewAdviceEvent, NewAdviceState> {
  Repository repository = Repository.getInstance();
  FlutterTts flutterTts = new FlutterTts()..setLanguage("en-US");

  @override
  NewAdviceState get initialState => InitialNewAdviceState();

  @override
  Stream<NewAdviceState> mapEventToState(
    NewAdviceEvent event,
  ) async* {
    switch (event.runtimeType) {
      case LoadNewEvent:
        yield* _mapLoadNewAdviceToState();
        break;
      case MarkAsFavouriteEvent:
        yield* _mapMarkAsFavouriteToState((event as MarkAsFavouriteEvent).advice);
        break;
      case ShowAdviceEvent:
        yield* _mapShowAdviceToState((event as ShowAdviceEvent).advice);
        repository.updateAdviceLastSeen((event as ShowAdviceEvent).advice.id);
        break;
      case SpeechAdviceEvent:
        await flutterTts.stop();
        await flutterTts.speak((event as SpeechAdviceEvent).advice.mainContent);
        break;
    }
  }

  Stream<NewAdviceState> _mapLoadNewAdviceToState() async* {
    yield LoadingNewAdviceState();
    Result<Advice> result = await repository.getRandomAdvice();
    if (result is SuccessResult) {
      yield LoadedAdviceState((result as SuccessResult).data);
    } else if (result is ErrorResult) {
      yield NotLoadedAdviceState((result as ErrorResult).error);
    }
  }

  Stream<NewAdviceState> _mapMarkAsFavouriteToState(Advice advice) async* {
    yield LoadedAdviceState(await repository.markAdviceAsFavourite(advice.id, !advice.isFavourite));
  }

  Stream<NewAdviceState> _mapShowAdviceToState(Advice advice) async* {
    yield LoadedAdviceState(await repository.setAdviceViews(advice.id, advice.views + 1));
  }
}
